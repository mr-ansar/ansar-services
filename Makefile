# Author: Scott Woods <scott.18.ansar@gmail.com.com>
# MIT License
#
# Copyright (c) 2022-2024
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
ID_USER=$(shell id --user --name)
ID_GROUP=$(shell id --group --name)
BACK?=10m

# Normal use;
all:
	@echo 'Build host or lan services "directory-host-service" or "directory-lan-service"'
	@echo 'Refer to README for details on setup of python environment.'
	@echo 'Then use "start" to execute the related software under the systemd framework.'
	@echo '$$ make directory-host-service'
	@echo '$$ make start'
	@echo '$$ make status'
	@echo '$$ make log BACK=10d'

# Useful lists of file names relating to executables
EXECUTABLES := ansar-group ansar-fixed ansar-product
BUILD := $(EXECUTABLES:%=dist/%)

# Default rule to turn a python script into an executable.
dist/% : %.py
	pyinstaller --onefile --log-level ERROR -p . $<

# Specific rules for library scripts.
dist/ansar-group:
	pyinstaller --onefile --log-level ERROR -p . `which ansar-group`

dist/ansar-fixed:
	pyinstaller --onefile --log-level ERROR -p . `which ansar-fixed`

dist/ansar-product:
	pyinstaller --onefile --log-level ERROR -p . `which ansar-product`

# Build portable images of the python scripts
build:: $(BUILD)

clean-build::
	-rm -rf build dist *.spec

# Form the process container.
ANSAR=.ansar-home

$(ANSAR): build
	ansar create
	ansar deploy dist

home: $(ANSAR)

# Populate the container with images for specific targets.
directory-host: home
	ansar add ansar-fixed directory-host
	ansar add ansar-product product-host
	ansar settings directory-host --settings-file=directory-host-settings
	ansar settings product-host --settings-file=product-host-settings
	ansar run --group-name=default --create-group
	ansar settings group.default --settings-file=group-directory-settings
	ansar set retry group.default --property-file=back-end-retry

directory-lan: home
	ansar add ansar-fixed directory-lan
	ansar add ansar-product product-lan
	ansar settings directory-lan --settings-file=directory-lan-settings
	ansar settings product-lan --settings-file=product-lan-settings
	ansar run --group-name=default --create-group
	ansar settings group.default --settings-file=group-directory-settings
	ansar set retry group.default --property-file=back-end-retry

clean-home:: clean-build
	-ansar -f destroy

# Create the service files as a collection of long-form make strings.
SYSTEM_D=/etc/systemd/system
DIRECTORY_HOST=ansar-host
DIRECTORY_HOST_SERVICE=$(DIRECTORY_HOST).service
DIRECTORY_HOST_INSTALLED=$(SYSTEM_D)/$(DIRECTORY_HOST_SERVICE)

define D_HOST_SERVICE
[Unit]
Description=Ansar Directory (HOST)
After=network.target

[Service]
User=$(ID_USER)
Group=$(ID_GROUP)
Type=forking
ExecStart=/usr/bin/env $(PWD)/$(DIRECTORY_HOST)-start
ExecStop=/usr/bin/env $(PWD)/$(DIRECTORY_HOST)-stop

[Install]
WantedBy=multi-user.target
endef

define D_HOST_START
#!/usr/bin/env bash
cd $(PWD)
source .services/bin/activate
ansar start
endef

define D_HOST_STOP
#!/usr/bin/env bash
cd $(PWD)
source .services/bin/activate
ansar --force stop
endef

#
#
DIRECTORY_LAN=ansar-lan
DIRECTORY_LAN_SERVICE=$(DIRECTORY_LAN).service
DIRECTORY_LAN_INSTALLED=$(SYSTEM_D)/$(DIRECTORY_LAN_SERVICE)

define D_LAN_SERVICE
[Unit]
Description=Ansar Directory (LAN)
After=network.target

[Service]
User=$(ID_USER)
Group=$(ID_GROUP)
Type=forking
ExecStart=/usr/bin/env $(PWD)/$(DIRECTORY_LAN)-start
ExecStop=/usr/bin/env $(PWD)/$(DIRECTORY_LAN)-stop

[Install]
WantedBy=multi-user.target
endef

define D_LAN_START
#!/usr/bin/env bash
cd $(PWD)
source .services/bin/activate
ansar start
endef

define D_LAN_STOP
#!/usr/bin/env bash
cd $(PWD)
source .services/bin/activate
ansar --force stop
endef

# Form a systemd service.
# Generate service, start and stop files.
# Link service file into systemd
# Use systemctl commands to install the service.
export D_HOST_SERVICE
$(DIRECTORY_HOST).service:
	echo "$$D_HOST_SERVICE" > $(DIRECTORY_HOST).service
	chmod 644 $(DIRECTORY_HOST).service

export D_HOST_START
$(DIRECTORY_HOST)-start:
	echo "$$D_HOST_START" > $(DIRECTORY_HOST)-start
	chmod 775 $(DIRECTORY_HOST)-start

export D_HOST_STOP
$(DIRECTORY_HOST)-stop:
	echo "$$D_HOST_STOP" > $(DIRECTORY_HOST)-stop
	chmod 775 $(DIRECTORY_HOST)-stop

directory-host-files: $(DIRECTORY_HOST).service $(DIRECTORY_HOST)-start $(DIRECTORY_HOST)-stop

$(DIRECTORY_HOST_INSTALLED): directory-host directory-host-files
	sudo ln $(DIRECTORY_HOST_SERVICE) $(SYSTEM_D)
	sudo systemctl daemon-reload
	sudo systemctl enable $(DIRECTORY_HOST_SERVICE)

directory-host-service: $(DIRECTORY_HOST_INSTALLED)

clean-directory-host:
	[ -e "$(DIRECTORY_HOST_INSTALLED)" ]
	sudo systemctl stop $(DIRECTORY_HOST_SERVICE)
	sudo systemctl disable $(DIRECTORY_HOST_SERVICE)
	sudo systemctl daemon-reload
	sudo rm $(DIRECTORY_HOST_INSTALLED)
	sudo rm $(DIRECTORY_HOST).service $(DIRECTORY_HOST)-start $(DIRECTORY_HOST)-stop

#
#
export D_LAN_SERVICE
$(DIRECTORY_LAN).service:
	echo "$$D_LAN_SERVICE" > $(DIRECTORY_LAN).service
	chmod 644 $(DIRECTORY_LAN).service

export D_LAN_START
$(DIRECTORY_LAN)-start:
	echo "$$D_LAN_START" > $(DIRECTORY_LAN)-start
	chmod 775 $(DIRECTORY_LAN)-start

export D_LAN_STOP
$(DIRECTORY_LAN)-stop:
	echo "$$D_LAN_STOP" > $(DIRECTORY_LAN)-stop
	chmod 775 $(DIRECTORY_LAN)-stop

directory-lan-files: $(DIRECTORY_LAN).service $(DIRECTORY_LAN)-start $(DIRECTORY_LAN)-stop

$(DIRECTORY_LAN_INSTALLED): directory-lan directory-lan-files
	sudo ln $(DIRECTORY_LAN_SERVICE) $(SYSTEM_D)
	sudo systemctl daemon-reload
	sudo systemctl enable $(DIRECTORY_LAN_SERVICE)

directory-lan-service: $(DIRECTORY_LAN_INSTALLED)

clean-directory-lan:
	[ -e "$(DIRECTORY_LAN_INSTALLED)" ]
	sudo systemctl stop $(DIRECTORY_LAN_SERVICE)
	sudo systemctl disable $(DIRECTORY_LAN_SERVICE)
	sudo systemctl daemon-reload
	sudo rm $(DIRECTORY_LAN_INSTALLED)
	sudo rm $(DIRECTORY_LAN).service $(DIRECTORY_LAN)-start $(DIRECTORY_LAN)-stop

# A few shorthands. Note use of ansar command
# for status and log. Ansar can only be used in a
# read-only fashion. Do not stop/start with ansar.
start:
	sudo systemctl start *.service

stop:
	sudo systemctl stop *.service

status:
	@ansar status -ll -ar -g

# Extract a page of logging for the installed service.
log:
	-@[ -e ansar-host.service ] && ansar log directory-host --back=$(BACK) "--count=`tput lines`" || true
	-@[ -e ansar-lan.service ] && ansar log directory-lan --back=$(BACK) "--count=`tput lines`" || true
