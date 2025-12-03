# Introduction

## Problem Statement
<p align="justify">
Data storage, management, accessibility and security are becoming an ever greater challenge in the modern digital age. Traditional data management methods often cannot keep pace with the growing volume of data and complex security requirements. From another perspective, increasingly intensive large-scale corporate services are being built on the accessibility and storage of user data, which often monopolize the market, limiting users' choices and increasing privacy risks, if not otherwise, then through continuous service fees or the loss of control over the data, for example by using it for data mining purposes.
</p>

<p align="justify">
In addition to the above, more and better-functioning private data storage and management solutions are appearing on the market, whose goal is to give users back control over their data while ensuring its secure storage and accessibility. These solutions often use decentralized systems that enable distributed storage and management of data, thereby reducing dependence on central service providers and increasing data security. However, in most cases operating these solutions requires significant technical knowledge, which limits their wider adoption, and at the same time can endanger security and availability, since their creators basically implement individual services and may not necessarily be able to meet complex data storage or access requirements.
</p>

**The Safebox can provide an appropriate solution to this.**

## Why We Need a New Approach

<p align="justify">
The Safebox solution is not the first attempt to bring together third-party standalone or community software service initiatives on a manageable platform. It is also not particularly new that a clean, easy-to-understand graphical interface continuously supports users in installing and managing services. In fact, there are many similar initiatives, some of which are open source, while others are closed source. These solutions can meet user needs to varying degrees, but they often lack key features that make the Safebox platform unique and efficient, such as a flexible and customizable template system, built-in domain management, or multiple geo-redundant backup options. These provide real advantages for users because if a user undertakes to build their own data management infrastructure, it must represent real value for them: it must be configurable and accessible as desired, understandable and easy to use, and it must not expose them to the risk of data loss.
</p>

## Key Features of the Safebox Platform
<p align="justify">
It is important to emphasize that Safebox does not aim to be just another software installer solution or yet another cloud-based storage service. Our goal is to create a well-manageable, easy-to-understand software platform that enables users to build their own data storage infrastructure, providing solutions equivalent to those of large providers, but without their disadvantages. The main characteristics of the Safebox platform are the following:
</p>

<p align="justify"><b>Can be used without a subscription - </b>The Safebox platform can be used without a subscription, as its core features are fully available without any ongoing fees. Users can install and manage services, store and access data locally, and access their data over the local network without any subscription.
</p>

<p align="justify">
Another built-in default software solution, backup and recovery, is also available without any subscription, with the limitation that its capabilities cannot extend beyond the boundaries of the local network. This ensures that users have full control over their data and services without being tied to a specific provider or service plan.
</p>

### Remote access (only available with subscription)

<p align="justify">
The remote access service is one of the most important features of the Safebox platform, enabling users to securely access their data and services from anywhere in the world. This function provides practically the same level of convenience and accessibility as the cloud-based services of major providers, without requiring users to share their data with third parties. Remote access operates over encrypted data streams, leveraging TCP-based routing proxy technology, which ensures the security and integrity of data during transmission. One of its key characteristics is that users' computers do not only become remote endpoints, but from the very beginning the first publicly trusted certificates are also created directly on their own machines. The generated certificates are stored locally in a verifiable way, and later, at any time, the issued certificates can be monitored and checked during data stream usage.
</p>

<p align="justify">
It is also important to emphasize that while the remote access service is a key element of the Safebox platform, its absence does not prevent the software from functioning; it only removes the option of remote access for users. This means that users of the Safebox platform can still access their data and services over the local network, or even directly on their Safebox device, without using the remote access feature. The service is intentionally designed as a paid component, which not only covers remote access itself, but also includes the management, registration and deletion of domains and subdomains, as well as the use of mobile applications. In addition, it provides further capabilities such as displaying traffic data, statistics, and similar functions. Use of these services is optional, and the core features of the Safebox platform remain fully available even without the remote access service. However, there is currently no provider that does not charge a fee for managing domains and ensuring public access; therefore, in the case of the Safebox platform, this is likewise a service whose use is subject to payment.
</p>

### Multiple georedundant backups (only available with subscription)

<p align="justify">
The possibility of backup and recovery is critically important for the security of personal data and services. By default, Safebox includes backup capabilities for the supported 3rd‑party applications, selectable per service. It shows which services are involved, how much data is associated with each, and what their current backup status is, while also storing the most relevant metadata. This service enables the user to back up their data to other machines running the Safebox platform within their local network, in automated and scheduled ways – all without involving any 3rd‑party provider. Data recovery is also available via the interface: after selecting the source and the restore point, the user can restore their data with a single click. It is important to emphasize that the Safebox platform only provides the capability; creating the backup locations (i.e., setting up and operating additional devices running the Safebox platform, configuring their network settings), and ensuring their availability, capacity, etc. is the user’s responsibility.
</p>

<p align="justify">
In addition to service‑specific backup and recovery options, the Safebox platform also allows users to create and use backup and recovery endpoints not only within their local network, but in geographically separated environments as well. As with the previously described local backup endpoints, the responsibility for setting up these remote endpoints lies with the user. At the same time, the platform also makes it possible for a user to cooperate with other Safebox users and store backup files on another Safebox user’s machine, naturally using compression and full data encryption. In this case, the data is indeed stored in a way that is no longer directly controlled by the user; however, the user can remotely delete it, and thanks to the default data encryption, only they have access to these backup files. Since this mode is fundamentally based on interpersonal relationships, it is up to the user to decide whom they trust.
</p>

<p align="justify">
This backup and recovery system can also operate in a cross‑provider manner, meaning that users of the Safebox platform can share their backup endpoints with one another, naturally while adhering to appropriate security measures. This system enables users to leverage the power of the community for secure data storage and recovery, while maintaining control over and the security of their own data.
</p>

### 3rd party service management via templates

<p align="justify">
The Safebox platform is designed so that the installation and management of available 3rd‑party applications are based on templates. These templates contain predefined configurations that simplify the installation and setup of applications, allowing users to quickly and easily access the desired services without requiring in‑depth technical knowledge.
</p>

<p align="justify">
The current solution manages the operation and configuration of applications based on a custom descriptor document. This document includes the steps required to start the application, configuration settings, the necessary and optional environment variables, and the dependencies of each application, such as descriptions of databases or other initialization applications. It also always includes descriptions of dependencies that are interpretable within the Safebox platform, such as handling local firewall settings or performing the domain registrations required for proxy services.
</p>

<p align="justify">
The templates follow the JSON format. The description of each function can be found in the Safebox default template directory, which is available at the following link: https://git.format.hu/safebox/default-applications-tree. The templates are open source, so users can modify or extend them according to their own needs.
</p>

<p align="justify">
At the same time, the Safebox platform can handle multiple template environments simultaneously. By forking the git repository mentioned above, users can create their own template environment, and by adding it to the platform, they can create and manage custom applications in Safebox.
</p>

<p align="justify">
Future plans include improving template management (currently only addition is supported, and only through a developer interface), which would allow templates to be managed directly through the Safebox web interface, including searching, adding, updating, and removing templates. Further plans include standardizing the custom descriptor document so that it works similarly to commonly used container descriptor formats such as Docker Compose or Kubernetes, thereby simplifying the creation and management of templates on the Safebox platform.
</p>

### Integrated domain management

<p align="justify">
Domain management consists of two parts: one is the general domain registration (or subdomain entry) service, which is closely linked to the Safebox platform’s remote access function; the other is handling internal domain name resolution between applications within Safebox. The former is only mentioned to the extent that the Safebox platform enables users, when using the remote access service, to easily register domain or subdomain names through the platform, which are then used for remote access. This service is part of the Safebox platform’s subscription‑based features, and the registration and management of domain names take place through the Safebox provider’s infrastructure. Naturally, so‑called primary domain registrations can also be carried out independently of Safebox; the service is primarily intended to simplify access to (mainly) web services related to domains or subdomains.
</p>

<p align="justify">
If the user decides at any time that they no longer wish to use the Safebox platform’s remote access service, the management of the registered domains and subdomains will not be discontinued; since it does not impose any significant load, it remains available, and only the remote access function itself becomes unavailable. At the same time, managing domain name resolution between applications within the Safebox platform is fundamentally important for the proper operation of the platform, as the system uses this to implement inter‑application communication and services. This function makes it possible for individual applications to easily find and reach each other within the Safebox platform, without having to configure complex network settings. This service is a core part of the Safebox platform and is available to every user, regardless of whether they use the remote access service or not. The service is called core‑dns and covers the management of the configuration of internal DNS services used by various components within the Safebox platform.
</p>

# What is the differencies between any existing solutions and our approach?

The primary goal of Safebox—beyond providing an easy‑to‑use platform for users—is to offer three key services that clearly distinguish it from similar solutions currently available on the market:

- complex, standalone, domain‑based web routing (with built‑in certificate management)
- a flexible, extensible, and freely manageable 3rd‑party app management system based on templates
- backup and recovery services across multiple geographically separated locations (both within and outside the local network)

Other important characteristics that competing solutions do not necessarily offer, but are integral parts of the Safebox platform:

- a fundamentally containerized, and therefore platform‑independent, solution
- domain-based data transfer service (subscription‑based)

## Why is Safebox better than other solutions?

<p align="justify">
Safebox simultaneously offers an integrated, “all‑in‑one” platform while still providing fully standalone, independent operation for the user. It does not lock you into any single provider: the system runs locally, and by default the data remains on the user’s own devices. Application installation, (local) domain management, web‑based access, and backup/restore are all available through a unified interface, so there is no need to stitch together separate systems. A key difference is that backup and restore are not optional extras, but built‑in, default services of the platform. From the very first start, users can design their setup so that the backup strategy is an organic part of day‑to‑day operations. Safebox supports both local and multiple, geographically separated backup endpoints, so high availability and protection against data loss are core capabilities, not premium add‑ons (except if the user chooses to use the PRO service associated with the Safebox platform). All this is achieved in a way that allows the user to switch at any time to a fully private operating mode independent of any provider, or, if desired, to opt into subscription‑based convenience features. The platform therefore gives users the freedom to define their own balance between tight integration and full independence.

## Who is this for?

<p align="justify">
In the short term, the Safebox platform almost instantly delivers a usable experience for anyone who wants to manage their own data and services without having to deal with complex technical configuration. This is particularly attractive for individuals who value privacy and security but do not have deep technical expertise. At the same time, in the longer term it does not exclude the possibility of gaining in‑depth knowledge either, since the openness and customizability of the platform allow users to gradually expand their skills and capabilities. In addition, Safebox can be an ideal choice for small and medium‑sized businesses that want to build their own data management infrastructure without making significant investments or operating complex systems.
</p>

<p align="justify">
At present, the Safebox platform supports a number of well‑known 3rd‑party applications that anyone can quickly and easily try out, even though in most cases these are completely unfamiliar solutions for users who are just getting to know the self‑hosted world. There is no risk for them, since installing and using the Safebox platform is free of charge, and users can at any time decide to try different applications without committing themselves to any specific service. This gives users the opportunity to explore the world of self‑hosted solutions and find the applications that best match their needs and expectations.
</p>

<p align="justify">
In the longer term, the goal of the Safebox platform is to support an increasing number of 3rd‑party applications and to enable users to create and share their own templates. In this way, the platform can evolve into a dynamically growing community ecosystem where users can share their experiences and knowledge with one another and jointly shape future developments. Safebox is therefore not only a tool for managing data, but also a community opportunity where users can actively participate in the evolution and direction of the platform.
</p>

# Technical Architecture

<p align="justify">
A detailed description of the technical architecture consists of two parts. One presents the components running on the user’s devices, and the other introduces the services that provide remote access.
</p>

## Concepts and Definitions

<p align="justify">
Before describing these two technical setups in detail, it is important to clarify a few basic concepts that will be referenced multiple times later. The original goal was for the Safebox platform to be an easy‑to‑use yet flexible and customizable solution that allows users to build their own data‑management infrastructure without requiring deep technical knowledge.

<p align="justify">
A key element is data security, one aspect of which is that no one can access the user's data except those whom the user explicitly authorizes. This is a fundamental requirement throughout the use of the software.

<p align="justify">
Additionally, it is a very important goal for the Safebox platform to serve as a long-term data storage solution that preserves the user's data even if they no longer subscribe to any services. However, the responsibility for the data remains with the user.
</p>
To this end, we introduced the following core concepts:

<ul>
<li>
<p align="justify">
<b>Safebox Device</b>: A Safebox device is a physical or virtual machine on which the Safebox platform runs. This can be a home server, a NAS device, or even a virtual machine running in the cloud. Third‑party applications run on Safebox devices, and this is where data is stored and managed.
</p>
</li>
<li>
<p align="justify">
<b>Template</b>: A template is a predefined configuration file that describes how to install and configure a given third‑party application on the Safebox platform. Templates allow users to quickly and easily access the desired services without needing detailed technical information; their primary purpose is to let users easily and quickly try out whether a given application meets their needs.
</p>
</li>
<li>
<p align="justify">
<b>Remote Access Service</b>: The remote access service enables users to securely access their data and services from anywhere in the world. This service operates over encrypted data streams and allows users to register their own domain or subdomain names through the Safebox platform.
</p>
</li>
<li>
<p align="justify">
<b>Backup and Recovery</b>: The backup and recovery service enables users to back up data to other Safebox devices within the local network, as well as to geographically separated locations. This service ensures high availability of data and protection against data loss.
</p>
</li>
</ul>

## Core Components

<p align="justify">
A Safebox platform installation consists of two core components that work together to provide a seamless user experience via Docker containers. These components are:
</p>
<ul>
<li>
<p align="justify"><b>webserver</b>: it is the primary user interface for managing the Safebox platform. It provides a clean, easy‑to‑understand graphical interface that allows users to install and manage third‑party applications, configure backup and recovery settings, and manage domain names. The web interface is accessible from any device with a web browser, making it easy for users to manage their data and services from anywhere. The web interface is built using nginx as a webserver and PHP for server-side logic. This component also uses the local file system by reading from and writing to a dedicated shared Docker volume to communicate with the other core component, the framework-scheduler. Whether through built‑in, periodically and automatically executed JavaScript calls, or through user interactions that require background operations, all requests are written in JSON format into this shared folder; more precisely, into <code>/var/tmp/shared/input</code> inside the SHARED Docker volume, which is written by this running container. The <code>output</code> directory, in turn, is written by the other component (framework-scheduler) after processing, and the webserver component reads these files as responses and displays the execution results to the user.</p>
</li>
<li>
<p align="justify"><b>framework-scheduler</b>: it is responsible for the core functionality of the platform. It uses the Linux kernel’s built‑in inotify mechanism to detect (read) any changes in the dedicated <code>/var/tmp/shared/input</code> folder, and writes the results of the executed requests in JSON format to the <code>/var/tmp/shared/output</code> folder after each action. The framework-scheduler uses the BusyBox shell to handle requests, because these are almost all low‑level Linux or container‑management commands, but there are plans to replace this with a higher‑level (Python‑based) interpreter implementation.</p>
</li>
</ul>

## Other Components

<p align="justify">
In addition to the two core components above, the Safebox platform consists of several additional, smaller components that complement and support the main functions. Some of them run continuously in the background, while others are created and stopped temporarily as needed and are then removed. These components are the following:
</p>
<ul>
<li>
<p align="justify"><b>core-dns</b>: a name resolution service that operates when access is enabled for the given process (UDP port 53 access for DNS resolution). It is needed when individual services running in isolated Docker networks require connectivity (for example, to enable email sending). Most commonly, however, it is used by firewall services when the generated IP address associated with a service name needs to be retrieved.</p>
</li>
<li>
<p align="justify"><b>cron</b>: a process created to provide periodically executed services. Its operation is extremely simple: it reads a file every second, generates a crontab format from it, and is able to run processes at the appropriate times. The most common use case is the daily execution of the letsencrypt process.</p>
</li>
<li>
<p align="justify"><b>loadbalancer and local-loadbalancer</b>: these containers are based on Alpine Linux and use the HAProxy solution. They run under the "haproxy" user instead of root privileges and operate using global variables set at process startup. The loadbalancer listens on TCP ports 80 and 443 and forwards packets via TCP to the backend proxies. The goal of this solution is twofold: first, incoming TCP packets (if they do not already have it) are assigned proxy protocol content; second, thanks to load balancing technology, TCP packets are forwarded to one of the two active backend proxies. This is important because configuration changes sometimes require restarting the backend proxies, but only one at a time, so the loadbalancer can always forward packets to an available proxy.</p>
</li>
<li>
<p align="justify"><b>backend-proxy</b>: these containers are based on Alpine Linux and use the Nginx server solution. For high availability, two instances must run on every Safebox platform. These services handle certificate verification, terminate SSL connections, and forward incoming data at the application layer (HTTP) without encryption to the actual applications, according to the web configuration files loaded at startup.</p>
</li>
<li>
<p align="justify"><b>proxy-scheduler</b>: this container is based on Alpine Linux and uses the Linux kernel’s inotify mechanism to monitor changes within the smarthost-domains directory. When changes are detected, it automatically starts and manages containers that update firewall rules, proxy configurations, and handle certificate requests as needed.</p>
</li>
<li>
<p align="justify"><b>wireguard-client</b>: this container provides WireGuard VPN-based network connectivity for services connected to the Safebox platform. It is part of the open-source software stack but is only started if the user enables the PRO subscription. Its operation is managed by functions built into the framework-scheduler, which retrieve the configuration files associated with the subscription and start the WireGuard VPN clients. (For remote access, a single instance runs; for providing georedundant backups to other users, multiple instances run—one for each supported user.)</p>
</li>
<li>
<p align="justify"><b>letsencrypt</b>: this container is based on Alpine Linux and uses the Letsencrypt-provided <code>acme.sh</code> script-based solution to handle domain-based certificate requests. For the service to function properly, the current domain value must not be <code>localhost</code>; in other words, a publicly accessible service must be available on TCP port 80 at the time of the certificate request.</p>
</li>
<li>
<p align="justify"><b>firewall</b>: this container type is Alpine-based and is run occasionally to configure firewall settings. Its main characteristic is that it reads the <code>core-dns</code> source and, based on the stored names and IP addresses, modifies network access between individual applications. After completing its tasks, it is always deleted.</p>
</li>
<li>
<p align="justify"><b>domain-checker</b>: this container type is Alpine-based and is run occasionally to create, modify or delete domain files which contain in JSON format the desired domain names and the related applications path.</p>
</li>
<li>
<p align="justify"><b>setup</b>: this is a container specifically responsible for starting, modifying or stopping additional Docker containers using Docker, as well as reading other key-value pairs defined in JSON format to provide the appropriate parameters. It also monitors dependencies described in the configuration and can manage container chains in various orders as required. After execution, it is always deleted.</p>
</li>
<li>
<p align="justify"><b>installer</b>: this container is primarily responsible for installing applications. It reads configuration files available in git format, which contain the required applications and the additional parameters needed for their execution in JSON format. After execution, it is always deleted.</p>
</li>
<li>
<p align="justify"><b>backup-server</b>: this is a service that is created during user setup and will be executed by the <code>cron</code> application at scheduled times as needed. It runs an Alpine-based SSH client in the background, and the Borg backup service performs data backup or restoration from previous backups based on user-specified parameters. This is under active development actually.</p>
</li>
<li>
<p align="justify"><b>backup-client</b>: this container type is Alpine-based and runs permanently in the background. Only one instance can run on a Safebox platform on behalf of the user, but it is possible to run additional instances on behalf of other users. The container includes an SSH server solution, which after initial setup is accessible only with the appropriate SSH key, and also contains a Borg backup client solution to securely and efficiently store the file content sent by the <code>backup-server</code>, encrypted and compressed, on a Docker volume. This is under active development actually.</p>
</li>
</ul>

## Implementation Details

<p align="justify">
The Safebox platform is implemented using Docker containers, which provide a flexible and scalable environment for running third-party applications. The purpose of containerization is to allow different applications and services to run isolated from each other; since these are third-party applications, network and filesystem isolation is required for enhanced security. Additionally, containerization enables each application to include only the dependencies it actually needs, reducing system resource usage and increasing both performance and security.
</p>

<p align="justify">
The framework-scheduler component is one of the core components of the platform; it must be started first and continuously runs in the background to handle user requests. Once the framework-scheduler has started, it performs checks, creates resources and routes if necessary, and then launches the webserver component, which provides the user interface. The webserver component then becomes accessible to users via their browser, allowing them to manage and configure the Safebox platform.
</p>

<p align="justify">
During installation and configuration of the Safebox platform, users can access the web interface, and the other components are loaded and started during the installation process.
</p>

<p align="justify">
The Safebox platform is also designed to be restarted at any time, either automatically or at the user's request; the necessary components will restart, and the user interface will become available again, with firewall settings checked and reconfigured as needed. (In many cases, this is a useful tool to reliably reach the desired stable state.)
</p>

<p align="justify">
A key element of the Safebox platform is the flexible, extensible template system, which allows users to easily install and manage various third-party applications. Templates are defined in JSON format and include the steps and settings required for installing and configuring applications. With templates, users can quickly and easily access desired services without needing deep technical knowledge. The templates are open source, available in git format, so users can modify or extend them according to their own needs.
</p>

<p align="justify">
The platform also includes a built-in backup and recovery solution, which can perform data backups and restores to the disks of multiple different machines within the local network. The data transfer protocol is SSH-based, and the actual backup and recovery operations are performed by the open-source BorgBackup solution. Backup processes can be scheduled and run automatically, while restore requests can be initiated manually via the user interface.
</p>

### About related services

<p align="justify">
It is important to emphasize that the goal of the Safebox platform is to create a data and service management infrastructure that is fully under the control and responsibility of the user. This does not require any additional subscription. However, certain features of the Safebox platform - primarily remote access and the use of geographically separated backup endpoints - are only available if the user either subscribes to Safebox services or provides their own domain and related proxy services. These services enable users to securely access their data and services from anywhere in the world, as well as to back up data to geographically separated locations or restore it from those locations.
</p>

<p align="justify">
The subscription-based services of the Safebox platform include domain name registration and management, as well as the ability to create any subdomain under the main domains provided free of charge by the provider. These domain services are complemented by proxy and backup client services provided via WireGuard VPN, as well as other features such as network monitoring or community backup HUB services. These services are optional, and the core functions of the Safebox platform remain fully accessible even without a subscription.
</p>

## System Requirements

<p align="justify">
The resource requirements of the Safebox platform itself are very low, but its later needs may vary depending on the services being run. The most important determining factor is the runtime environment, which (currently) requires the ability to run Docker containers. Fast disk read/write capability is essential for Docker to function properly, so at least an SSD drive is recommended. Another recommended system requirement is the use of redundant disks (RAID or similar solutions), since the primary goal of the Safebox platform is the secure storage and management of data, and providing the necessary hardware background is the user's responsibility. However, this is only a recommendation, not a mandatory requirement, as users can ensure regular backups; thus, even if the storage device temporarily fails, they can restore their data, only having to endure service downtime during the replacement.
</p>

<p align="justify">
Another hardware requirement may be the presence of a suitable processor that supports containerization technologies (e.g., Intel VT-x or AMD-V). These technologies enable Docker to efficiently isolate containers from each other and from the host, thereby increasing security and performance. Both Intel and ARM processors are supported.
</p>

<p align="justify">
In certain cases, such as media streaming services, hardware acceleration support may also be advantageous, so the presence of dedicated video cards is recommended. However, this is not a mandatory requirement, and the Safebox platform is fundamentally based on software solutions.
</p>

## Security Considerations

<p align="justify">
During the operation of the Safebox platform, numerous security measures are implemented to ensure that users' data and services are protected from unauthorized access and other threats. First and foremost, the operating environment stands out: containerization and the use of isolated runtime environments significantly reduce the risk that compromising one application could have system-wide effects. Another layer of security is provided by the implementation of separated network operations between individual applications, which prevents one application from directly accessing another. Additionally, the Safebox platform includes a built-in firewall service that allows fine-tuning of network access rules between applications, further enhancing system security.
</p>

<p align="justify">
One of the key security features of the Safebox platform is the remote access service, which enables users to securely access their data and services worldwide via encrypted data streams. This service uses TCP-based routing proxy technology, ensuring that neither unauthorized parties nor even the provider can read the data stream, as it is encrypted using OpenSSL. As part of the remote access service, the Safebox platform itself handles the authentication of domain names (and subdomains also), so users can be confident that only those they explicitly authorize can access their data. The generated certificates are stored locally on the user's machine and can be verified at any time.
</p>

<p align="justify">
The Safebox platform also includes a built-in backup and recovery service, allowing users to back up their data to other Safebox devices within the local network as well as to geographically separated locations. This service ensures high data availability and protection against loss. The backup processes use an SSH-based data transfer protocol, and the actual backup and recovery operations are performed by the open-source BorgBackup solution. Both backups and restores utilize BorgBackup's built-in encryption mechanism, so only the user can access their data, even when it is stored in geographically separated locations.
</p>

# Template Use Cases

<p align="justify">
The Safebox platform supports a variety of third-party applications through its flexible template system. Safebox is capable of managing multiple template environments simultaneously, handling overlaps as well. The basic descriptor format is a JSON key-value pair. Accordingly, template management follows the pattern below:
</p>

<ul>
<li>
Each application is registered twice (this is because during the initial read, only the <code>applications-tree.json</code> file is loaded, and the images managed for the applications may differ), but it is important that for every application listed in the <code>applications-tree.json</code> file, a corresponding directory with the same name must also exist.
</li>
<li>
Each application's directory must contain a <code>template.json</code> file, which includes the variables required for installing and configuring the given application, along with their default values. These variables are presented to the user during the installation process via the user interface.
</li>
<li>
An application's directory may also contain a JSON file starting with <code>service-*</code>, which holds all the parameters necessary for launching all instances of the given application together.
</li>
<li>
An application's directory may contain one or more files starting with <code>firewall-*</code>, which specify the firewall rules associated with the given service.
</li>
<li>
An application's directory may contain one or more files starting with <code>domain-*</code>, which specify the domain requirements associated with the given service.
</li>
</ul>
<p align="justify">
You can read more about the detailed template management capabilities of the Safebox platform in the documentation.
</p>

# Future Work

# Conclusion
