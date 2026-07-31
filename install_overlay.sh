#!/bin/bash

if command -v rsync 2>/dev/null 1>&2; then
	rsync -av overlay/etc/ /etc/
	rsync -av overlay/usr/ /usr/
else
	cp -rav overlay/etc/ /etc/
	cp -rav overlay/usr/ /usr/
fi
