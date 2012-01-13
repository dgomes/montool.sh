#!/bin/sh
IMETERURL="http://192.168.1.103/listdev.htm"
AIRPORTIP="192.168.1.72"
ARDUINOIP="192.168.1.76"

LAST=

echo "Content-type: application/json\n"

json_string () {
	if [ "$LAST" = "VAL" ]; then
		echo -n ','
	fi
	echo -n \"
	echo -n $1
	echo -n \":\"
	echo -n $2
	echo -n \"
	LAST="VAL"
}

json_number () {
	if [ "$LAST" = "VAL" ]; then
		echo -n ','
	fi
	echo -n \"
	echo -n $1
	echo -n \":
	echo -n $2
	LAST="VAL"
}

json_array () {
	if [ "$LAST" = "VAL" ]; then
		echo -n ','
	fi
	if [ -z $1 ]; then
		echo -n ']'
	else
		echo -n \"$1\"
		echo ':['
	fi
	LAST="ARRAY"
}

json_obj () {
	if [ "$LAST" = "OBJ" ]; then
		echo ,
	fi	

	if [ -z $1 ]; then
		echo -n '{'
	else
		echo -n '}'
		LAST="OBJ"
	fi
}

diff_val_shm () {
	VAL=$1
	SHM=/dev/shm/$2
	if [ -e $SHM ]; then
		PREVIOUS_VAL=`cat $SHM`
		echo $VAL > $SHM 
		R=`echo ${VAL}-${PREVIOUS_VAL} | bc`
	else	
		echo $VAL > $SHM 
		R=0
	fi
	return $R
}

cpu () {

  CPU=`cat /proc/stat | grep '^cpu ' | cut -d\  -f 2-` # Get the total CPU statistics.
  PREV_IDLE=` echo $CPU | cut -d\  -f 4` # Get the total CPU statistics.

  # Calculate the total CPU time.
  PREV_TOTAL=0
  for VALUE in ${CPU}; do
    PREV_TOTAL=$(($PREV_TOTAL+$VALUE))
  done
  
  # Wait before checking again.
  sleep 1

  CPU=`cat /proc/stat | grep '^cpu ' | cut -d\  -f 2-` # Get the total CPU statistics.
  IDLE=` echo $CPU | cut -d\  -f 4` # Get the total CPU statistics.

  # Calculate the total CPU time.
  TOTAL=0
  for VALUE in ${CPU}; do
    TOTAL=$(($TOTAL+$VALUE))
  done
 
  # Calculate the CPU usage since we last checked.
  DIFF_IDLE=$(($IDLE-$PREV_IDLE))
  DIFF_TOTAL=$(($TOTAL-$PREV_TOTAL))
  DIFF_USAGE=$((1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL))
  DIFF_USAGE_UNITS=$(($DIFF_USAGE/10))
  DIFF_USAGE_DECIMAL=$(($DIFF_USAGE%10))
  json_number "cpu" $DIFF_USAGE_UNITS.$DIFF_USAGE_DECIMAL 


}

diskspace () {
	DF=`df | tail -n +2`
	i=0
	json_array "items"
	for item in $DF; do
		case $(($i % 6 )) in
		0)	
			json_obj
			json_string "device" $item 
			;;
		4)
			json_number "use" ${item%?}
			;;
		5)
			json_string "mounted" $item
			json_obj end
			;;
		esac
		i=$((i+1))
	done	
	json_array
}

processes () {
	IFS='
'
	PS=`ps auxww | tail -n +2`
	i=0
	json_array "processes"
	for LINE in $PS; do
		IFS=' '
		json_obj
		json_string "CPU" `echo $LINE | cut -d\  -f 3 `
		json_string "MEM" `echo $LINE | cut -d\  -f 4 `
		json_string "COMMAND" "`echo $LINE | cut -d\  -f 11- `"
		i=$((i+1))
		json_obj end
	done
	json_array
	unset $IFS
}

info () {
	IFS='
'
	MSG=`hostname`.`hostname -d`
	json_string "hostname" $MSG
	MSG=`hostname -i`
	json_string "ip" $MSG
	json_string "servername" $SERVER_NAME
	MSG=`uname -a`
	json_string "uname" $MSG 
	json_string "server" $SERVER_SIGNATURE
	MSG=`uptime`
	json_string "uptime" $MSG 
	unset $IFS 
}

upnp () {
	OSHM="upnp.out.shm"
	ISHM="upnp.in.shm"
	TSHM="upnp.time.shm"

	UPNP=`upnpc -s | grep Bytes`
	OUT=`echo ${UPNP} | cut -d: -f3 | cut -c2-12`
	IN=`echo ${UPNP} | cut -d: -f4`

	NOW=`date +%s`
	diff_val_shm $NOW $TSHM
	ELAPSED=$?
	
	diff_val_shm $OUT $OSHM
	ODIFF=$?
	ORATE=`echo ${ODIFF}*8/\(${ELAPSED}*1024\) | bc`

	diff_val_shm $IN $ISHM
	IDIFF=$?
	IRATE=`echo ${IDIFF}*8/\(${ELAPSED}*1024\) | bc`
		
	json_string "version" "1.0.0"
	json_array "datastreams"
	
	json_obj
	json_string "id" "inBytes" 
	json_number "current_value" $IN 
	json_obj end 
	
	json_obj 
	json_string "id" "outBytes" 
	json_number "current_value" $OUT
	json_obj end
	
	json_obj
	json_string "id" "downloadRate"
	json_number "current_value" $IRATE
	json_obj end

	json_obj
	json_string "id" "uploadRate"
	json_number "current_value" $ORATE
	json_obj end

	json_array
}

airport () {
	OSHM="airport.out.shm"
	ISHM="airport.in.shm"
	TSHM="airport.time.shm"
	CLIENTS=`snmpget -v 2c -c public ${AIRPORTIP} .1.3.6.1.4.1.63.501.3.2.1.0 -Ovq`
	OUT=`snmpget -v 2c -c public ${AIRPORTIP} .1.3.6.1.2.1.2.2.1.16.6 -Ovq`
	IN=`snmpget -v 2c -c public ${AIRPORTIP} .1.3.6.1.2.1.2.2.1.10.6 -Ovq`
	
	NOW=`date +%s`
	diff_val_shm $NOW $TSHM
	ELAPSED=$?
	
	diff_val_shm $OUT $OSHM
	OUTDIFF=$?
	ORATE=`echo ${OUTDIFF}*8/\(${ELAPSED}*1024\) | bc`
	diff_val_shm $IN $ISHM
	INDIFF=$?
	IRATE=`echo ${INDIFF}*8/\(${ELAPSED}*1024\) | bc`
		
	json_string "version" "1.0.0"
	json_array "datastreams"
	
	json_obj 
	json_string "id" "numberWirelessClients" 
	json_number "current_value" $CLIENTS 
	json_obj end
	
	json_obj 
	json_string "id" "inOctets" 
	json_number "current_value" $IN 
	json_obj end
	
	json_obj 
	json_string "id" "outOctets" 
	json_number "current_value" $OUT 
	json_obj end

	json_obj
	json_string "id" "downloadRate"
	json_number "current_value" $ORATE
	json_obj end

	json_obj
	json_string "id" "uploadRate"
	json_number "current_value" $IRATE
	json_obj end

	json_array

}

arduino () {
	tmp=`echo g | nc ${ARDUINOIP} 23`
	TEMP="${tmp%?}"
	json_string "version" "1.0.0"
	json_array "datastreams"
	
	json_obj
	json_string "id" "temperature" 
	json_number "current_value" $TEMP
	json_obj end

	json_array
}

imeter () {
	ENERGY=`wget -q -O - ${IMETERURL} | grep Wh | cut -b 25- | cut -d \  -f 1`
        POWER=`wget -q -O - ${IMETERURL} | grep "W&nbsp" | cut -b 25- | cut -d \  -f 1`
	json_string "version" "1.0.0"
	json_array "datastreams"
	
	json_obj 
	json_string "id" "energy" 
	json_string "current_value" $ENERGY 
	json_obj end
	
	json_obj 
	json_string "id" "power" 
	json_string "current_value" $POWER 
	json_obj end

	json_array
}

memory () {
	FREE=`free | tail -n +2 | head -n 1`
	i=0
	for item in $FREE; do
		case $(($i % 6 )) in
		1)
			json_number "total" $item;;
		2)
			json_number "used" $item;;
		3)
			json_number "free" $item;;
		esac	
		i=$((i+1))
	done
}

json_obj
IFS=$"|"
parm=$QUERY_STRING
unset IFS

for arg in $parm; do 

	case $arg in
	info)
		info;;
	df)
		diskspace;;
	free)
		memory;;
	ps)
		processes;;
	imeter)
		imeter;;
	arduino)
		arduino;;
	airport)
		airport;;
	upnp)
		upnp;;
	stat)
		cpu;;
	esac

done
json_obj end

