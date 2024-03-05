# ansar-services
Methods and materials for construction of ansar networks

This repo contains the files and commands needed to manufacture two components
of ansar networking. These are;

* the ansar directory that runs at HOST level,
* and the ansar directory that runs at LAN level.

These components are mutually exclusive - they should never be operational
on the same host.

This repo is cloned onto the target host and with a few commands the target
is configured with an instance of the appropriate directory. The target can be
a host supporting normal multi-processing and ansar networking, such as a
development machine or an operational host. The other type of target is the
host designated to be the ansar LAN directory.

> Default use of the commands in this repo assume a standard configuration
> for ansar networking. This includes use of a standard port (32175) and a
> standard IP address (192.168.1.176). Different values can be adopted by editing
> the directory-host-settings and directory-lan-settings files before service
> construction begins. Use of non-standard values requires on-going administrative
> discipline. Refer to ansar-connect documentation for further details.

To enable full ansar networking capabilities within a development or operational
host, install the ansar-host.service;

```
git clone git@github.com:mr-ansar/ansar-services.git
cd ansar-services
python3 -m venv .services
source .services/bin/activate
pip3 install pyinstaller ansar-connect
make directory-host-service
make start
make status
make log
```

To enable full ansar networking capabilities within the scope of a
LAN, install the ansar-lan.service. There is exactly one or none
instances of this service in any given LAN. The target host is assumed
to be a 24-by-7 server, located at an expected IP address (see note
above).

```
git clone git@github.com:mr-ansar/ansar-services.git
cd ansar-services
python3 -m venv .services
source .services/bin/activate
pip3 install pyinstaller ansar-connect
make directory-lan-service
make start
make status
make log
```
