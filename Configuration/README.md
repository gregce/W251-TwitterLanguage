# VM Provisioning
Our first step was to configure the bare metal servers:
- Prerequiste is to have softlayer configured and an API token installed on your local client
- Open a local terminal session and execute the following command for however many nodes you want (changing the parameter values where appropriate)
- ```slcli vs create --datacenter=sjc01 --domain=gregceccarelli.com --hostname=p1 --os=UBUNTU_14_64  --cpu=4 --memory=8192  --disk=100 --disk=100 --billing=hourly```
- In my case, I ran it nine times for nodes p1 - p9

# Local Client Setup
Prepare your local client to make remote administration of your cluster easy:
- ```Run slcli vs list``` to obtain the hostnames and ip address from all your newly created servers
- edit your /etc/hosts to include all of these
- download and install csshX (cluster SSH) on your local client. If on mac, you can use the following formula: http://brewformulas.org/csshx
- https://github.com/brockgr/csshx/blob/master/README.txt
- Obtain the credentials from all your baremetal servers (I used the below cript to do so):
```
nodeid=`slcli vs list | awk '$2 ~/p/ {print $1} {print $2}'`

for i in $nodeid; do
            echo $i
            slcli vs credentials $i
        done
```
- Public Key Authentication: From the client machine, we run `ssh-keygen` to generate a keypair
- We use `ssh-copy-id mids@p1` to copy our public key to our remote servers... repeat this process for each server


# Remote Node Configuration
### Initial Config
To be completed on each node via csshX:
 - Configure /etc/hosts: sudo nano /etc/hosts
    ```
    127.0.0.1 localhost.localdomain localhost <node hostname>
    192.155.215.8 node1.gregceccarell.com node1
    192.155.215.9 node2.gregceccarell.com node2
    192.155.215.14 node3.gregceccarell.com node3
    192.155.215.2 node4.gregceccarell.com node4
    192.155.215.13 node5.gregceccarell.com node5
    etc
    ```
- Once you are logged in as `root`, we're prepared to add the new user account that we will use to log in from now on:
- `adduser mids` You will be asked a few questions, starting with the account password.
- Now, we have a new user account with regular account privileges. However, we may sometimes need to do administrative tasks.
- To add these privileges to our new user, we need to add the new user to the "sudo" group. By default, on Ubuntu 14.04, users who belong to the "sudo" group are allowed to use the sudo command.
- As root, run this command to add your new user to the sudo group: `gpasswd -a demo sudo`
- Public Key Authentication Between Servers: From the p1, we run `ssh-keygen` to generate a keypair
- We use `ssh-copy-id mids@p1` to copy our public key to our remote servers... repeat this process for each server. We can then test that each server can communicate with each other by attempting to SSH from p1 to p2 for example.

 
### 100G Disk Formatting
* You need to find out the name of our disk, e.g
        fdisk -l |grep Disk |grep GB
        - OR -
        cat /proc/partitions

* Assuming your disk is called `/dev/xvdc` as it is for me,
    ``` mkdir /data; mkfs.ext4 /dev/xvdc```

* Add this line to `/etc/fstab` (with the appropriate disk path):

        /dev/xvdc /data                   ext4    defaults,noatime        0 0

* Mount your disk and set the appropriate perms:

        mount /data
        chmod 1777 /data

### Software Config
**Installing & Configuring Cassandra**
- Step one is to ensure Oracle's JRE is installed as it is a requirement
- You can run the following commands:
    - `sudo add-apt-repository ppa:webupd8team/java`
    - `sudo apt-get update`
    - `sudo apt-get install oracle-java8-set-default`
    - Verify the installation: `java -version`
    - Should receive output like below:
    > Output
java version "1.8.0_60"
Java(TM) SE Runtime Environment (build 1.8.0_60-b27)
Java HotSpot(TM) 64-Bit Server VM (build 25.60-b23, mixed mode)

- Step two is to actuall install cassandra
- We used the following sequence of commands across our nodes:
    - `echo "deb http://www.apache.org/dist/cassandra/debian 22x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list`
    - `echo "deb-src http://www.apache.org/dist/cassandra/debian 22x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list`
    - Adding keys:
    - `gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D`
    - `gpg --export --armor F758CE318D77295D | sudo apt-key add -`
    - `gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00`
    - `gpg --export --armor 2B5C1B00 | sudo apt-key add -`
    - `gpg --keyserver pgp.mit.edu --recv-keys 0353B12C`
    - `gpg --export --armor 0353B12C | sudo apt-key add -`
    - Updating the package repo:
    - `sudo apt-get update`
    - Installing: `sudo apt-get install cassandra`
- Once that is completed on each node, one must


  
  
**Installing Anaconda**


**Installing & Configuring Spark**


**Installing Shiny Server**

