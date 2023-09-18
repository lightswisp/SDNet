
# SDNet

SDNet is a network privacy solution, similar to a rotating proxy principle, comprising four essential components: the client, dispenser server, multiple proxy servers, and a webserver. Its core principle is to offer users a discreet and secure online experience by masking network activity from prying eyes and circumventing the censorship.

### Client Perspective:
From the user's viewpoint, SDNet operates seamlessly. The client initiates a connection to the dispenser server, retrieves the list of active proxy servers, and then disconnects. These proxy servers are temporarily stored in memory and are switched automatically at irregular intervals between 3 to 15 minutes, akin to a rotating proxy system. This randomization mimics genuine user behavior, making it difficult for ISPs to distinguish SDNet from regular web browsing. Even if a curious ISP investigates the proxy server's address, it appears as a legitimate webpage with HTML and CSS, further obfuscating its true purpose as a censorship circumvention tool.

![](https://github.com/lightswisp/SDNet/blob/main/media/client.gif?raw=true)

### Proxy Server Perspective:
Each proxy server actively communicates with the dispenser server upon launch, signaling its availability by saying, "Hey, I'm alive! Add me to the list." Once online, these proxy servers patiently await connections from clients.

![](https://github.com/lightswisp/SDNet/blob/main/media/server.gif?raw=true)
