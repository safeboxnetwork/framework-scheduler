# Introduction

## Problem Statement
<p align="justify">
Data storage, management, accessibility and security are becoming an ever greater challenge in the modern digital age. Traditional data management methods often cannot keep pace with the growing volume of data and complex security requirements. From another perspective, increasingly intensive large-scale corporate services are being built on the accessibility and storage of user data, which often monopolize the market, limiting users’ choices and increasing privacy risks, if not otherwise, then through continuous service fees or the loss of control over the data, for example by using it for data mining purposes.

In addition to the above, more and better-functioning private data storage and management solutions are appearing on the market, whose goal is to give users back control over their data while ensuring its secure storage and accessibility. These solutions often use decentralized systems that enable distributed storage and management of data, thereby reducing dependence on central service providers and increasing data security. However, in most cases operating these solutions requires significant technical knowledge, which limits their wider adoption, and at the same time can endanger security and availability, since their creators basically implement individual services and may not necessarily be able to meet complex data storage or access requirements.
</p>

**The Safebox can provide an appropriate solution to this.**

## Why We Need a New Approach

<p align="justify">
The Safebox solution is not the first attempt to bring together third‑party standalone or community software service initiatives on a manageable platform. It is also not particularly new that a clean, easy‑to‑understand graphical interface continuously supports users in installing and managing services. In fact, there are many similar initiatives, some of which are open source, while others are closed source. These solutions can meet user needs to varying degrees, but they often lack key features that make the Safebox platform unique and efficient, such as a flexible and customizable template system, built‑in domain management, or multiple geo‑redundant backup options. These provide real advantages for users because if a user undertakes to build their own data management infrastructure, it must represent real value for them: it must be configurable and accessible as desired, understandable and easy to use, and it must not expose them to the risk of data loss.
</p>

## Key Features of the Safebox Platform
<p align="justify">
It is important to emphasize that Safebox does not aim to be just another software installer solution or yet another cloud‑based storage service. Our goal is to create a well‑manageable, easy‑to‑understand software platform that enables users to build their own data storage infrastructure, providing solutions equivalent to those of large providers, but without their disadvantages. The main characteristics of the Safebox platform are the following:

### Remote access

<p align="justify">
The remote access service is one of the most important features of the Safebox platform, enabling users to securely access their data and services from anywhere in the world. This function provides practically the same level of convenience and accessibility as the cloud‑based services of major providers, without requiring users to share their data with third parties. Remote access operates over encrypted data streams, leveraging TCP‑based routing proxy technology, which ensures the security and integrity of data during transmission. One of its key characteristics is that users’ computers do not only become remote endpoints, but from the very beginning the first publicly trusted certificates are also created directly on their own machines. The generated certificates are stored locally in a verifiable way, and later, at any time, the issued certificates can be monitored and checked during data stream usage.
</p>

<p align="justify">
It is also important to emphasize that while the remote access service is a key element of the Safebox platform, its absence does not prevent the software from functioning; it only removes the option of remote access for users. This means that users of the Safebox platform can still access their data and services over the local network, or even directly on their Safebox device, without using the remote access feature. The service is intentionally designed as a paid component, which not only covers remote access itself, but also includes the management, registration and deletion of domains and subdomains, as well as the use of mobile applications. In addition, it provides further capabilities such as displaying traffic data, statistics, and similar functions. Use of these services is optional, and the core features of the Safebox platform remain fully available even without the remote access service. However, there is currently no provider that does not charge a fee for managing domains and ensuring public access; therefore, in the case of the Safebox platform, this is likewise a service whose use is subject to payment.
</p>

### Multiple georeduntant backups

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

### Integrated domain management


# What is the differencies between any existing solutions and our approach?

## Why is it better?

## Who is this for?

# Technical Architecture

## Concepts and Definitions

## Core Components

## Implementation Details

## System Requirements

## Security Considerations

# Template Use Cases

# Future Work

# Conclusion