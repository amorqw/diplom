#!/bin/bash

echo '<html><head><meta http-equiv="refresh" content="30"></head><body><table border="1">' > hd.html
date "+%Y-%m-%d %H:%M:%S" >> hd.html
echo '<tr><th>Terminal</th><th>Online</th><th>HDD_VOl</th><th>USAGE</th><th>HDD %</th></tr>' >> hd.html
while read -r line; do
    echo '<tr> ' >> hd.html
    ipad=$(echo $line |  cut -d ' ' -f2) # вычленили IP адрес их списка в переменную
    log_in=$(echo $line |  cut -d ' ' -f3) # вытащили из списка Login для авторизации
    echo '<td>' >> hd.html
    echo $(echo $line |  cut -d ' ' -f1) >> hd.html # Вытащили из списка подпись
    echo '</td>' >> hd.html

# проверяем на доступность в сети по пингу

    case  $(ping $ipad -c 2 | grep received | cut -c 24) in
	0) 
	    #echo ERROR
	    echo '<td>ERROR</td>' >> hd.html
	    ;;
	1) 	
	    #echo NOT OK
	    echo '<td>NOT OK</td>' >> hd.html
	    ;;
	2) 
	    #echo OK
	    echo '<td>OK</td>' >> hd.html
	    ;;
    esac
    echo '<td>' >> hd.html

#через SSH получаем HDD Volume and usage

    hdd_vol=$(ssh -n $log_in@$ipad  df --total / | tail -n 1 |  tr -s ' ' | cut -d ' ' -f2 )
    if [ -n "$hdd_vol" ]
	then 	   echo $hdd_vol >> hd.html
	else	   echo NO_CONN >> hd.html
		    hdd_vol=0
    fi
    echo '</td>' >> hd.html
    echo '<td>' >> hd.html

# проверяем сколько памяти на диске занято

    hdd_use=$(ssh -n $log_in@$ipad  df --total / | tail -n 1 | tr -s ' ' | cut -d ' ' -f3 )
    if [ -n "$hdd_use" ]
	then   echo $hdd_use >> hd.html
	else   echo NO_CONN >> hd.html
    fi
    echo '</td>' >> hd.html
    echo '<td><b> ' >> hd.html
# Процент загрузки диска
    if [ "$hdd_vol" -eq 0 ];
	then persen=ERROR
#	    echo error1
        else persen=$((100 * hdd_use / hdd_vol))
#	    echo error2
    fi
    eit=80
#    echo $persen
    if [ "$persen" -lt "$eit" ] ;
	then echo '<p style="color: green;">' >> hd.html
	else echo '<p style="color: red" > ' >> hd.html
    fi
    echo $persen >> hd.html
    echo '% </b></p></td>' >> hd.html
    echo '</tr> ' >> hd.html
done < /home/monitor/scripts/term_list

echo '</table></body></html>' >> hd.html
cp hd.html /var/www/html/hd.html