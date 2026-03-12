#!/bin/bash

echo '<html><head><meta http-equiv="refresh" content="30"></head><body><table border="1">' > ram.html
date "+%Y-%m-%d %H:%M:%S" >> ram.html
echo '<tr><th>Terminal</th><th>Online</th><th>RAM_VOl</th><th>USAGE</th><th>RAM %</th></tr>' >> ram.html
while read -r line; do
    echo '<tr> ' >> ram.html
    ipad=$(echo $line |  cut -d ' ' -f2) # вычленили IP адрес их списка в переменную
    log_in=$(echo $line |  cut -d ' ' -f3) # вытащили из списка Login для авторизации
    echo '<td>' >> ram.html
    echo $(echo $line |  cut -d ' ' -f1) >> ram.html # Вытащили из списка подпись
    echo '</td>' >> ram.html

# проверяем на доступность в сети по пингу

    case  $(ping $ipad -c 2 | grep received | cut -c 24) in
	0) 
	    #echo ERROR
	    echo '<td>ERROR</td>' >> ram.html
	    ;;
	1) 	
	    #echo NOT OK
	    echo '<td>NOT OK</td>' >> ram.html
	    ;;
	2) 
	    #echo OK
	    echo '<td>OK</td>' >> ram.html
	    ;;
    esac
    echo '<td>' >> ram.html

#через SSH получаем RAM Volume and usage

    ram_vol=$(ssh -n $log_in@$ipad  free --mega | grep Mem | tr -s ' '| cut -d ' ' -f2 )
    if [ -n "$ram_vol" ]
	then 	   echo $ram_vol >> ram.html
	else	   echo NO_CONN >> ram.html
    fi
    echo '</td>' >> ram.html
    echo '<td>' >> ram.html

# проверяем сколько оперативной памяти в работе

    ram_use=$(ssh -n $log_in@$ipad  free --mega | grep Mem | tr -s ' ' | cut -d ' ' -f3 )
    if [ -n "$ram_use" ]
	then   echo $ram_use >> ram.html
	else   echo NO_CONN >> ram.html
    fi
    echo '</td>' >> ram.html
    echo '<td><b> ' >> ram.html
# Процент загруженности оперативной памяти

    persen=$((100 * ram_use / ram_vol))
    eit=80
    if [ "$persen" -lt "$eit" ] ;
	then echo '<p style="color: green;">' >> ram.html
	else echo '<p style="color: red" > ' >> ram.html
    fi
    echo $persen >> ram.html
    echo '% </b></p></td>' >> ram.html
    echo '</tr> ' >> ram.html
done < /home/monitor/scripts/term_list

echo '</table></body></html>' >> ram.html
cp ram.html /var/www/html/ram.html