# PERCEIVE (PERformanCe EstImation for VR vidEos)

This appendix provides a detailed description of the procedure to be followed in order to allow reproducibility of the experiments performed in this work. All the employed datasets and source code are available at the PERCEIVE repository. The reader interested in the full paper may refer to:

Roberto Irajá Tavares da Costa Filho, Maria Torres Vega, Marcelo Caggiani Luizelli, Jeroen van der Hooft, Stefano Petrangeli, Tim Wauters, Filip De Turck, Luciano Paschoal Gaspary. PREDICTING THE PERFORMANCE OF VIRTUAL REALITY VIDEO STREAMING IN MOBILE NETWORKS. ACM Multimedia Systems Conference. Amsterdam, June 12 - 15, 2018, (MMSys'18).

-------------------------------------------------------------------------------------------------------------

EXPERIMENTAL PROCEDURE OVERVIEW AND SPECIFICATIONS

The experimental procedure is split into three steps. First, the VR video player requests tile-based videos, from a web server, while subjected to controlled network conditions. The VR video player is responsible for measuring and recording the VR video playout performance, while the network conditions are enforced by Linux Traffic Control (TC) mechanism. Second, the VR video playout performance indicators are given as input to the machine learning process. At this stage, machine learning is responsible for characterizing how each network condition impacts the video playout performance. Finally, in the third step, an estimation of QoE is provided by giving the VR video performance as input to the QoE model.

To perform the first step, we employ three dedicated virtual machines deployed on the imec iLab.t Virtual Wall emulation platform {imec iLab.t: http://doc.ilabt.iminds.be/ilabt-documentation/virtualwallfacility.html}. The first machine was used to run the VR video player, while the second was used to host tile-based VR videos using a regular Apache web server. Through traditional IP routing and Linux Traffic Control (TC), the third machine was configured as a gateway between the other two, acting as a network condition enforcement point. Each virtual machine was configured with a quad-core Intel Xeon E3-1220 v3 CPU running at 3.10GHz, 15GB RAM, 16GB of storage and running Linux Ubuntu 14.04 (3.13.0-33). The full list of packages and its respective versions is available at PERCEIVE's repository (Setup/packages.txt).

Steps two and three do not require any specific hardware or software specification. Step two was performed using R (1.0.143), and for the third step we employed a simple electronic spreadsheet to compute the QoE model over the VR video playout performance indicators. After this overview, the remainder of this section will cover practical details of the main elements of the experiment.


TILE-BASED HAS VR-VIDEO RE-ENCODING

In order to generate tile-based HAS VR-videos, it was necessary to re-encode the original VR videos from Wu et al.' s dataset (namely ``Google Spotlight-HELP" and ``Freestyle Skiing"). Herein, the re-encoding procedure is explained step-by-step.

- After downloading the original VR-videos ``Google Spotlight-HELP" {https://youtu.be/G-XZhKqQAHU}} and ``Freestyle Skiing" {https://youtu.be/0wC3x_bnnps}, the raw videos must be first extracted using the following command of FFMPEG {FFMPEG: https://www.ffmpeg.org/}:

  $ ffmpeg -i inVideo.mkv -c:v rawvideo outVideo.yuv

- Next, the HEVC tile-based version of the videos is generated using Kvazaar Kvazaar: {https://github.com/ultravideo/kvazaar}. Kvazaar splits the videos based on the generated YUV file, the desired tiling scheme, resolution and frames per second (FPS), as shown in the following example. This command is to be executed per video quality. 

  $ kvazaar -i outVideo.yuv --input-res 3840x2160 -o outVideo12x4.hevc --tiles 12x4 --slices tiles --mv-constraint frametilemargin -q 30 --period 30 --input-fps 30

- Subsequently, each of the tiles of the VR-video is packed into an mp4 container employing the MP4Box software \footnote{MP4box: \url{https://gpac.wp.imt.fr/mp4box/}}. 

  $ MP4Box -add outVideo12x4.hevc:split_tiles -fps 30 -new video_tiled_4K_12x4.mp4

- Finally, based on the desired length of the HAS segment, the per-tile per segment files of the VR-video are extracted. For example, the following command defines one second for the segment length, 12x4 tiling scheme and three video resolutions (720p, 1080p and 4K). This procedure also generates MPD files by using multiple quality representations.

  $ MP4Box -dash 1000 -rap -frag-rap -profile live -out has_tiled_12x4.mpd ../SOURCE/video_tiled_720_12x4.mp4 ../SOURCE/video_tiled_1080_12x4.mp4 ../SOURCE/video_tiled_4K_12x4.mp4

VR VIDEO PLAYER

Both the source code and binary for the VR video player are available at the PERCEIVE repository (VR-player/Source and VR-player/bin respectively). The player provides support to variable tiling scheme and can be adapted to several QoE zone schemes. Additionally, the player supports viewport traces (a previously recorded log regarding the user’s head track) as input. The player is written in C language and employs Curl library to perform HTTP requests. The player also allows parameters to be passed through command line arguments. It is particularly useful when running large experiments, so that the player parameterization can be done dynamically by an external script. For example, the following player call is used for requesting the first 60 segments of the video named “video2”, available at the IP “10.0.0.251”, using the viewport trace stored in the file “user1/video2.txt”, using 100 seconds timeout and a 12x4 tiling scheme. In this case, the resultant VR-video playout performance will be written in the file named “video2playout”.

$ VR-player 10.0.0.251 video2 60 video2playout user1/video2.txt 100 4 12

VIDEO PLAYOUT AND NETWORK DATASETS

The file ``Sample.csv" (directory ``Network dataset" provides the 48 network conditions considered in our experiments. The configuration ID is the leftmost field in the file ``Sample.csv", followed by the fields throughput TCP (Mb/s), delay (msec) and packet loss rate (\%). After parsed, these values are given as input to the Linux TC, which act as a network condition enforcement point.

In turn, the file ``playoutPerformance.txt" (directory ``Playout performance dataset" provides the resultant output of the first step of the experimental procedure. Furthermore, this is the same file given as input to the machine learning process (step two). Along with the network dataset.

MACHINE LEARNING

The directory ``R Scripts" provides all the source code used to generate the regression decision trees. Each of the eight decision trees has its own source code (R script). In addition to the R tool, we employed the following packages: stargazer https://cran.r-project.org/web/packages/stargazer/index.html}}, gdata {https://cran.r-project.org/web/packages/gdata/index.html}, rpart {https://cran.r-project.org/web/packages/rpart/index.html}, tree {https://cran.r-project.org/web/packages/tree/index.html} and rpart.plot {https://cran.r-project.org/web/packages/rpart.plot/index.html}. Finally, it is worth mentioning that the trees shown in this work were obtained through their optimal prune. Which means that during the prune stage, we selected the complexity parameter (CP) associated with the minimum cross-validation error (xerror).
