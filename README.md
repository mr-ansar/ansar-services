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

To enable full ansar networking capabilities within a development or operational
host, install the ansar-host.service;

```
git clone git@github.com:mr-ansar/ansar-services.git
cd ansar-services
python3 -m venv .dev
source .dev/bin/activate
pip3 install pyinstaller ansar-connect
make directory-host-service
sudo systemctl start ansar-host.service 
sudo systemctl status ansar-host.service 
ansar status -ll -ar -g
ansar log directory-host
sudo systemctl status ansar-host.service
```

To enable full ansar networking capabilities within the scope of a
LAN, install the ansar-lan.service. There is exactly one or none
instances of this service in any given LAN. The target host is assumed
to be a 24-by-7 server.

```
git clone git@github.com:mr-ansar/ansar-services.git
cd ansar-services
python3 -m venv .dev
source .dev/bin/activate
pip3 install pyinstaller ansar-connect
make directory-lan-service
sudo systemctl start ansar-lan.service 
sudo systemctl status ansar-lan.service 
ansar status -ll -ar -g
ansar log directory-lan
sudo systemctl status ansar-lan.service
```

