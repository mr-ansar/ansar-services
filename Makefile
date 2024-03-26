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

# Normal use;
all:
	@echo 'Build host or lan services "ansar-host-service" or "ansar-lan-service"
	@echo 'Refer to README for details on setup of python environment.'
	@echo 'Then use "start" to execute the related software under the systemd framework.'
	@echo '$$ make ansar-host-service'
	@echo '$$ make start'
	@echo '$$ make status'

# Useful lists of file names relating to executables
EXECUTABLES := ansar-group ansar-directory shared-directory
BUILD := $(EXECUTABLES:%=dist/%)

# Default rule to turn a python script into an executable.
dist/% : %.py
	pyinstaller --onefile --log-level ERROR -p . $<

# Specific rules for library scripts.
dist/ansar-group:
	pyinstaller --onefile --log-level ERROR -p . `which ansar-group`

dist/ansar-directory:
	pyinstaller --onefile --log-level ERROR -p . `which ansar-directory`

dist/shared-directory:
	pyinstaller --onefile --log-level ERROR -p . `which shared-directory`

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
ansar-host: home
	ansar add ansar-directory reserved-host
	ansar add ansar-directory dedicated-host
	ansar add shared-directory shared-host
	ansar settings reserved-host --settings-file=reserved-host.settings
	ansar settings dedicated-host --settings-file=dedicated-host.settings
	ansar settings shared-host --settings-file=shared-host.settings
	ansar run --group-name=default --create-group
	ansar settings group.default --settings-file=group-default.settings
	ansar set retry group.default --property-file=back-end.retry

ansar-lan: home
	ansar add ansar-directory reserved-lan
	ansar add ansar-directory dedicated-lan
	ansar add shared-directory shared-lan
	ansar settings reserved-lan --settings-file=reserved-lan.settings
	ansar settings dedicated-lan --settings-file=dedicated-lan.settings
	ansar settings shared-lan --settings-file=shared-lan.settings
	ansar run --group-name=default --create-group
	ansar settings group.default --settings-file=group-default.settings
	ansar set retry group.default --property-file=back-end.retry

clean-home:: clean-build
	-rm -rf .ansar-home

# Create the service files as a collection of long-form make strings.
SYSTEM_D=/etc/systemd/system
ANSAR_HOST=ansar-host
ANSAR_HOST_SERVICE=$(ANSAR_HOST).service
ANSAR_HOST_INSTALLED=$(SYSTEM_D)/$(ANSAR_HOST_SERVICE)

define D_HOST_SERVICE
[Unit]
Description=Ansar Directory (HOST)
After=network.target

[Service]
User=$(ID_USER)
Group=$(ID_GROUP)
Type=forking
ExecStart=/usr/bin/env $(PWD)/$(ANSAR_HOST)-start
ExecStop=/usr/bin/env $(PWD)/$(ANSAR_HOST)-stop

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
ANSAR_LAN=ansar-lan
ANSAR_LAN_SERVICE=$(ANSAR_LAN).service
ANSAR_LAN_INSTALLED=$(SYSTEM_D)/$(ANSAR_LAN_SERVICE)

define D_LAN_SERVICE
[Unit]
Description=Ansar Directory (LAN)
After=network.target

[Service]
User=$(ID_USER)
Group=$(ID_GROUP)
Type=forking
ExecStart=/usr/bin/env $(PWD)/$(ANSAR_LAN)-start
ExecStop=/usr/bin/env $(PWD)/$(ANSAR_LAN)-stop

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
$(ANSAR_HOST).service:
	echo "$$D_HOST_SERVICE" > $(ANSAR_HOST).service
	chmod 644 $(ANSAR_HOST).service

export D_HOST_START
$(ANSAR_HOST)-start:
	echo "$$D_HOST_START" > $(ANSAR_HOST)-start
	chmod 775 $(ANSAR_HOST)-start

export D_HOST_STOP
$(ANSAR_HOST)-stop:
	echo "$$D_HOST_STOP" > $(ANSAR_HOST)-stop
	chmod 775 $(ANSAR_HOST)-stop

ansar-host-files: $(ANSAR_HOST).service $(ANSAR_HOST)-start $(ANSAR_HOST)-stop

$(ANSAR_HOST_INSTALLED): ansar-host ansar-host-files
	sudo ln $(ANSAR_HOST_SERVICE) $(SYSTEM_D)
	sudo systemctl daemon-reload
	sudo systemctl enable $(ANSAR_HOST_SERVICE)

ansar-host-service: $(ANSAR_HOST_INSTALLED)

clean-ansar-host:
	[ -e "$(ANSAR_HOST_INSTALLED)" ]
	sudo systemctl stop $(ANSAR_HOST_SERVICE)
	sudo systemctl disable $(ANSAR_HOST_SERVICE)
	sudo systemctl daemon-reload
	sudo rm $(ANSAR_HOST_INSTALLED)
	sudo rm $(ANSAR_HOST).service $(ANSAR_HOST)-start $(ANSAR_HOST)-stop

#
#
export D_LAN_SERVICE
$(ANSAR_LAN).service:
	echo "$$D_LAN_SERVICE" > $(ANSAR_LAN).service
	chmod 644 $(ANSAR_LAN).service

export D_LAN_START
$(ANSAR_LAN)-start:
	echo "$$D_LAN_START" > $(ANSAR_LAN)-start
	chmod 775 $(ANSAR_LAN)-start

export D_LAN_STOP
$(ANSAR_LAN)-stop:
	echo "$$D_LAN_STOP" > $(ANSAR_LAN)-stop
	chmod 775 $(ANSAR_LAN)-stop

ansar-lan-files: $(ANSAR_LAN).service $(ANSAR_LAN)-start $(ANSAR_LAN)-stop

$(ANSAR_LAN_INSTALLED): ansar-lan ansar-lan-files
	sudo ln $(ANSAR_LAN_SERVICE) $(SYSTEM_D)
	sudo systemctl daemon-reload
	sudo systemctl enable $(ANSAR_LAN_SERVICE)

ansar-lan-service: $(ANSAR_LAN_INSTALLED)

clean-ansar-lan:
	[ -e "$(ANSAR_LAN_INSTALLED)" ]
	sudo systemctl stop $(ANSAR_LAN_SERVICE)
	sudo systemctl disable $(ANSAR_LAN_SERVICE)
	sudo systemctl daemon-reload
	sudo rm $(ANSAR_LAN_INSTALLED)
	sudo rm $(ANSAR_LAN).service $(ANSAR_LAN)-start $(ANSAR_LAN)-stop

# A few shorthands. Note use of ansar command
# for status and log. Ansar can only be used in a
# read-only fashion. Do not stop/start with ansar.
start:
	sudo systemctl start *.service

stop:
	sudo systemctl stop *.service

status:
	@ansar status -ll -ar -g
