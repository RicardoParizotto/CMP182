/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>


const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_ARP = 0x0806;
const bit<32> MAX_PORTS = 1 << 16;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}
/*
 --- note that first 64 bits are not required for my implementation 
 */

header arp_ipv4_t {
    bit<64> lixo;
    bit<48>    src_mac;
    bit<32>   src_ip;
    bit<48>     dst_mac;         
    bit<32>    dst_ip;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct metadata {
   
    //this metadata is the hash output on the table pipeline. 
    bit<14> ecmp_select;
    //
    bit<2> AVOID_LOOP;
}

struct headers {
    ethernet_t   ethernet;
    arp_ipv4_t    arp;
    ipv4_t       ipv4;
    tcp_t	 tcp;
}




/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            TYPE_ARP:  parse_arp;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
           6: parse_tcp;
           default: accept;
        }
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {


    action drop() {
        mark_to_drop();
    }
    
     /*hashs the packet-in using crc16. Put the result of the (hash % ecmp_count) + ecmp_base on meta.ecmp_select*/
    action set_ecmp_select(bit<16> ecmp_base, bit<32> ecmp_count) {
        hash(meta.ecmp_select,
	    HashAlgorithm.crc16,
	    ecmp_base,
	    { hdr.ipv4.srcAddr,
	      hdr.ipv4.dstAddr,
              hdr.ipv4.protocol,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort },
	    ecmp_count);

	    meta.AVOID_LOOP = 1;
    }

   /*set the output_port to 'port'	*/
   action simple_forward (egressSpec_t port){
         standard_metadata.egress_spec = port;
    }

    /*set the output_port to 'port' and decrement ttl of the ipv4 header*/
    action set_nhop( egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    /*set set output_port to 'port' and decrement ttl of the ipv4 header. update the ethernet header source and destination*/	
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table arp_send{
        key = {
           hdr.arp.dst_ip: lpm;
        }
        actions = {
           simple_forward;
	   NoAction;
        }
        size = 1024;
        default_action= NoAction();
     }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            simple_forward;
            set_ecmp_select;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    table ecmp_nhop {
        key = {
            meta.ecmp_select: exact;
        }
        actions = {
            drop;
            NoAction;
            set_nhop;
        }
        size = 4;
       default_action=NoAction();
    }

    apply {
        if(hdr.arp.isValid()){
            arp_send.apply();
        }else{
	        if (hdr.ipv4.isValid()) {
	            ipv4_lpm.apply();
	
	            if(meta.AVOID_LOOP == 1){
	           	     ecmp_nhop.apply();
         	     }	
		}
         }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
   

   
    counter(MAX_PORTS, CounterType.packets_and_bytes) egressCounter;


    /*Update counters of ports of this device. Whenever a packet is sent to a output port, this egress updates the number of bytes and packets the already passed*/   

    action count_packets() {
        egressCounter.count((bit<32>)  standard_metadata.egress_port);
    }

    apply {
         count_packets();
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;