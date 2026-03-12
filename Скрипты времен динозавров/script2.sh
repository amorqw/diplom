#!/bin/bash

echo '<html><head><meta http-equiv="refresh" content="30"></head><body><table border="1">' > mon.html
date "+%Y-%m-%d %H:%M:%S" >> mon.html
echo '<tr><th>Terminal</th><th>Online</th><th>Kiosk</th><th>RFID</th></tr>' >> mon.html
while read -r line; do
    echo '<tr> ' >> mon.html
    ipad=$(echo $line |  cut -d ' ' -f2) # вычленили IP адрес их списка в переменную
    log_in=$(echo $line |  cut -d ' ' -f3) # вытащили из списка Login для авторизации
    echo '<td>' >> mon.html
    echo $(echo $line |  cut -d ' ' -f1) >> mon.html # Вытащили из списка подпись
    echo '</td>' >> mon.html

# проверяем на доступность в сети по пингу

    case  $(ping $ipad -c 2 | grep received | cut -c 24) in
	0) 
	    #echo ERROR
	    echo '<td>ERROR</td>' >> mon.html
	    ;;
	1) 	
	    #echo NOT OK
	    echo '<td>NOT OK</td>' >> mon.html
	    ;;
	2) 
	    #echo OK
	    echo '<td>OK</td>' >> mon.html
	    ;;
    esac
    echo '<td>' >> mon.html

#через SSH проверяем запущено ли приложение KioskBrowser

#    ssh $log_in@$ipad ps -eF | grep /opt/KioskBrowser/KioskBrowser

    sshlog=$(ssh -n $log_in@$ipad  ps -eF | grep /opt/KioskBrowser/KioskBrowser )

# проверяем если у нас служба по другому написана и мы случайно не нашли

    if [ -z "$sshlog" ]; # проверка пустую строку
	then     sshlog=$(ssh -n $log_in@$ipad  ps -eF | grep /opt/KioskBrowser/kioskbrowser )
    fi
# проверяем нашли или не нашли

    if [ -n "$sshlog" ]; #проверка на непустую строку
	 then echo 'OK' >> mon.html
	else echo 'ERROR' >>  mon.html
     fi
    echo '</td>' >> mon.html
    echo '<td>' >> mon.html

# проверяем запустился ли скрипт считывания RFID меток, подключения настроек Touch и логирования

#    ssh $log_in@$ipad ps -eF | grep /opt/KioskBrowserStart

    sshlog=$(ssh -n $log_in@$ipad  ps -eF | grep /opt/KioskBrowserStart )

    if [ -n "$sshlog" ];
	 then echo 'OK' >> mon.html
	else echo 'ERROR' >>  mon.html
     fi
    echo '</td>' >> mon.html
    echo '</tr> ' >> mon.html
done < /home/monitor/scripts/term_list

echo '</table></body></html>' >> mon.html
cp mon.html /var/www/html/mon.html