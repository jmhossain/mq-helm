# Name: gen-mqsc-2-qmgrs qmgr1 host1 port1 qmgr2 host2 port2
# Linux bash
# Purpose: generate 2 files for runmqsc to generate all the commands
#          to fully connect 2 queue managers using sender-receiver channels.
# The output file name that begins with qmgr1 needs to be run for qmgr1
# The output file name that begins with qmgr2 needs to be run for qmgr2
# The following is the general format for running the mqsc file via runmqsc
#   runmqsc qmgr1 < qmgr1.qmgr2.mqsc
#
# The commands that are generated are:
#  define listener(LISTENER) in both qmgrs
#  define local queue Q5 in qmgr1 and Q6 in qmgr2
#  define remote queue definition that begins with Q6 and Q5
#  define 2 sender - receiver pairs: 
#     qmgr1.qmgr2 for the flow from qmgr1 to qmgr2
#     qmgr2.qmgr1 for teh flow from qmgr2 to qmgr1

echo "arguments $#"
if [[ "$#" -ne 6 ]]; then
  echo "Usage: gen-mqsc-2-qmgrs qmgr1 host1 port1 qmgr2 host2 port2"
  exit 
fi

qmgr1=$1
host1=$2
port1=$3
qmgr2=$4
host2=$5
port2=$6
file1=$qmgr1.$qmgr2.mqsc
file2=$qmgr2.$qmgr1.mqsc

echo "Create File: $file1"

echo "** QMgr1: $qmgr1 " > $file1

echo "alter qmgr chlauth (DISABLED)" >> $file1

# Define and start a Listener. 
echo "define listener(LISTENER) trptype(tcp) control(qmgr) port($port1) replace" >> $file1
echo "start listener(LISTENER) " >> $file1

# Define a local queue:
echo "define qlocal(Q5) replace " >> $file1

# Define a local queue (used for transmission):
echo "define qlocal($qmgr2) usage(xmitq) replace " >> $file1

# Define a remote queue definition by typing the following command: 
echo "define qremote(Q6_$qmgr2) rname(Q6) rqmname($qmgr2) xmitq($qmgr2) replace " >> $file1

# Define a receiving channel by typing the following command: 
echo "define channel($qmgr2.$qmgr1) chltype(RCVR) trptype(TCP) replace " >> $file1

# Define a sender channel by typing the following command: 
echo "define channel($qmgr1.$qmgr2) chltype(SDR) conname('$host2($port2)') xmitq($qmgr2) trptype(TCP) replace " >> $file1

# Start the sender channel
echo "start channel($qmgr1.$qmgr2) "  >> $file1

echo "end" >> $file1


echo "Create File: $file2"

echo "** QMgr2: $qmgr2 " > $file2

echo "alter qmgr chlauth (DISABLED)" >> $file2

# Define and start a Listener. 
echo "define listener(LISTENER) trptype(tcp) control(qmgr) port($port2) replace" >> $file2
echo "start listener(LISTENER)" >> $file2

# Define a local queue:
echo "define qlocal(Q6) replace" >> $file2

# Define a local queue (used for transmission):
echo "define qlocal($qmgr1) usage(xmitq) replace" >> $file2

# Define a remote queue definition by typing the following command: 
echo "define qremote(Q5_$qmgr1) rname(Q5) rqmname($qmgr1) xmitq($qmgr1) replace" >> $file2

# Define a receiving channel by typing the following command: 
echo "define channel($qmgr1.$qmgr2) chltype(RCVR) trptype(TCP) replace" >> $file2

# Define a sender channel by typing the following command: 
echo "define channel($qmgr2.$qmgr1) chltype(SDR) conname('$host1($port1)') xmitq($qmgr1) trptype(TCP) replace" >> $file2

# Start the sender channel
echo "start channel($qmgr2.$qmgr1)" >> $file2

echo "end" >> $file2

echo "end of script"

