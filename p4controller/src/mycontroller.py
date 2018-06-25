#!/usr/bin/env python2
import argparse
import os
from time import sleep

# NOTE: Appending to the PYTHON_PATH is only required in the `solution` directory.
#       It is not required for mycontroller.py in the top-level directory.
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import p4runtime_lib.bmv2
import p4runtime_lib.helper

import csv

'''

:param p4info_helper: the P4Info helper
:param ingress_sw: the ingress switch connection
:param egress_sw: the egress switch connection
:param tunnel_id: the specified tunnel ID
:param dst_eth_addr: the destination IP to match in the ingress rule
:param dst_ip_addr: the destination Ethernet address to write in the
                    egress rule
'''
def writeIpv4Rule(p4info_helper, ingress_sw, dst_ip_addr, dst_eth_addr, switch_port, prefix_size):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr, prefix_size)
        },
        action_name="MyIngress.ipv4_forward",
        action_params={
            "dstAddr": dst_eth_addr,
            "port": switch_port
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name  


def writeArpRule(p4info_helper, ingress_sw, dst_ip_addr, switch_port, prefix_size, tunnel_id):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.arp_send",
        match_fields={
            "hdr.arp.dst_ip": (dst_ip_addr, prefix_size)
        },
        action_name="MyIngress.arp_forward",
        action_params={
            "port": switch_port,
            "dst_id": tunnel_id
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name     


def writeBalancingEntry(p4info_helper, ingress_sw, dst_ip_addr, ecmp_base, ecmp_count, prefix_size):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr, prefix_size)
        },
        action_name="MyIngress.set_ecmp_select",
        action_params={
            "ecmp_base": ecmp_base,
            "ecmp_count": ecmp_count
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name


def setNextHop(p4info_helper, ingress_sw, ecmp_select, switch_port):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ecmp_nhop",
        match_fields={
            "meta.ecmp_select": ecmp_select
        },
        action_name="MyIngress.set_nhop",
        action_params={
            "port": switch_port
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name


def simpleForwarding(p4info_helper, ingress_sw, dst_ip_addr, switch_port, prefix_size):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.ipv4_lpm",
        match_fields={
            "hdr.ipv4.dstAddr": (dst_ip_addr, prefix_size)
        },
        action_name="MyIngress.simple_forward",
        action_params={
            "port": switch_port
        })
    ingress_sw.WriteTableEntry(table_entry)
    print "Installed ingress tunnel rule on %s" % ingress_sw.name






def readTableRules(p4info_helper, sw):
    '''
    Reads the table entries from all tables on the switch.

    :param p4info_helper: the P4Info helper
    :param sw: the switch connection
    '''
    print '\n----- Reading tables rules for %s -----' % sw.name
    for response in sw.ReadTableEntries():
        for entity in response.entities:
            entry = entity.table_entry
            # TODO For extra credit, you can use the p4info_helper to translate
            #      the IDs the entry to names
            table_name = p4info_helper.get_tables_name(entry.table_id)
            print '%s: ' % table_name,
            for m in entry.match:
                print p4info_helper.get_match_field_name(table_name, m.field_id),
                print '%r' % (p4info_helper.get_match_field_value(m),),
            action = entry.action.action
            action_name = p4info_helper.get_actions_name(action.action_id)
            print '->', action_name,
            for p in action.params:
                print p4info_helper.get_action_param_name(action_name, p.param_id),
                print '%r' % p.value,
            print

def printCounter(p4info_helper, sw, counter_name, index):
    '''
    Reads the specified counter at the specified index from the switch. In our
    program, the index is the tunnel ID. If the index is 0, it will return all
    values from the counter.

    :param p4info_helper: the P4Info helper
    :param sw:  the switch connection
    :param counter_name: the name of the counter from the P4 program
    :param index: the counter index (in our case, the tunnel ID)
    '''

    for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), index):
        for entity in response.entities:
            counter = entity.counter_entry
            print "%s %s %d: %d packets (%d bytes)" % (
                sw.name, counter_name, index,
                counter.data.packet_count, counter.data.byte_count
            )

def snapshoting(p4info_helper, sw, counter_name, index):
    '''
    Reads the specified counter at the specified index from the switch. In our
    program, the index is the tunnel ID. If the index is 0, it will return all
    values from the counter.

    :param p4info_helper: the P4Info helper
    :param sw:  the switch connection
    :param counter_name: the name of the counter from the P4 program
    :param index: the counter index (in our case, the tunnel ID)
    '''

    last_snapshot = {}
    last_snapshot[1] = 0
    last_snapshot[2] = 0


    asdfsdf = {}
    asdfsdf[1] = 0
    asdfsdf[2] = 0

    myFile =  open('eggs.csv', 'w')


    try:
        while True:
            sleep(10)
            for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), 2):
                for entity in response.entities:
                    counter = entity.counter_entry
                    asdfsdf[1] = (counter.data.byte_count - last_snapshot[2])
                    last_snapshot[2] = counter.data.byte_count

            for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), 3):
                for entity in response.entities:
                    counter = entity.counter_entry
                    asdfsdf[2] = (counter.data.byte_count - last_snapshot[1])
                    last_snapshot[1] = counter.data.byte_count

            writer = csv.writer(myFile)
            writer.writerow([asdfsdf[1],asdfsdf[2]])            
                            
    except KeyboardInterrupt:
        print " Shutting down."



def main(p4info_file_path, bmv2_file_path):
    # Instantiate a P4 Runtime helper from the p4info file
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    # Create switch connection objects;
    # this is backed by a P4 Runtime gRPC connection
    # use a dict here  //ricardo

    switches = {}

    switches["s1"] = p4runtime_lib.bmv2.Bmv2SwitchConnection('s1', 
                                                 address='127.0.0.1:50051',
                                                 device_id=0)

    switches["s2"] = p4runtime_lib.bmv2.Bmv2SwitchConnection('s2', 
                                                 address='127.0.0.1:50052',
                                                 device_id=1)

    switches["s3"] = p4runtime_lib.bmv2.Bmv2SwitchConnection('s3', 
                                                 address='127.0.0.1:50053',
                                                 device_id=2)


    # Install the P4 program on switches
    for k, sw in switches.items():
        sw.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                   bmv2_json_file_path=bmv2_file_path)
        print "Installed P4 Program using SetForwardingPipelineConfig on %s" % sw.name

    # Write the rules that tunnel traffic from h1 to h3


    #writeArpRule(p4info_helper, switches["s1"], "10.0.1.2", 2, 32)
    #writeArpRule(p4info_helper, switches["s1"], "10.0.1.1", 1, 32)


    #path1 2 -> 1
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.1.1", "00:00:00:00:01:01", 9, 32)

    #delivering video
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.2", "00:00:00:00:02:02", 1, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.3", "00:00:00:00:02:03", 2, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.4", "00:00:00:00:02:04", 3, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.5", "00:00:00:00:02:05", 4, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.6", "00:00:00:00:02:06", 5, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.7", "00:00:00:00:02:07", 6, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.8", "00:00:00:00:02:08", 7, 32)
    writeIpv4Rule(p4info_helper, switches["s2"], "10.0.2.9", "00:00:00:00:02:09", 8, 32)


    #request to server
    writeIpv4Rule(p4info_helper, switches["s1"], "10.0.1.1", "00:00:00:00:01:01", 1, 32)

    #(without balancing) path 1 -> 2
    # writeIpv4Rule(p4info_helper, switches["s1"], "10.0.2.0", "00:00:00:00:02:02", 2, 24)

    #path 1 -> 2 -> 3
    simpleForwarding(p4info_helper, switches["s3"], "10.0.2.0", 2, 24)

    

    #turn on balancer
    writeBalancingEntry(p4info_helper,ingress_sw=switches["s1"], dst_ip_addr="10.0.2.0", ecmp_base=0, ecmp_count=2, prefix_size=24)
    setNextHop(p4info_helper, ingress_sw=switches["s1"], ecmp_select=1, switch_port=2)
    setNextHop(p4info_helper, ingress_sw=switches["s1"], ecmp_select=0, switch_port=3)
    
    

    # TODO Uncomment the following two lines to read table entries from s1 and s2
    readTableRules(p4info_helper, switches["s1"])
    readTableRules(p4info_helper, switches["s2"])


    snapshoting(p4info_helper, switches["s1"], "MyEgress.egressCounter", 0)
    '''
    try:
        while True:
            sleep(2)
            print '\n----- Reading tunnel counters -----'
            printCounter(p4info_helper, switches["s1"], "MyEgress.egressCounter", 1)
            printCounter(p4info_helper, switches["s1"], "MyEgress.egressCounter", 2)
            printCounter(p4info_helper, switches["s1"], "MyEgress.egressCounter", 3)

    except KeyboardInterrupt:
        print " Shutting down."
    '''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
                        type=str, action="store", required=False,
                        default='./build/advanced_tunnel.p4info')
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
                        type=str, action="store", required=False,
                        default='./build/advanced_tunnel.json')
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print "\np4info file not found: %s\nHave you run 'make'?" % args.p4info
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print "\nBMv2 JSON file not found: %s\nHave you run 'make'?" % args.bmv2_json
        parser.exit(1)

    main(args.p4info, args.bmv2_json)
