#! /bin/bash

. /usr/local/lib/pglet.sh

pglet_page greeter

pglet_send "clean"
txt_name=`pglet_send "add textbox label='Your name' description='Please provide your full name'"`
btn_hello=`pglet_send "add button primary text='Say hello'"`

while true
do
    pglet_wait_event
    if [[ "$PGLET_EVENT_TARGET" == $btn_hello && "$PGLET_EVENT_NAME" == "click" ]]; then
        name=`pglet_send "get $txt_name value"`
        pglet_send "clean page"
        pglet_send "add text value='Hello, $name'"
        pglet_send "add text value='Close browser window to exit the program...'"
        break
    fi
done
