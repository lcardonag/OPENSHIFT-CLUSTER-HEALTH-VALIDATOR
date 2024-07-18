## **OPENSHIFT-CLUSTER-HEALTH-VALIDATOR**

**1. CONTEXT:**

*"Currently, most of the modern applications that are developed are containerized and to achieve this containerization there are several ways, among the most recommended and the one we recommend is that they be deployed in an OPENSHIFT Cluster."*
<p> </p>
<p> </p>

**2. USE CASE:**

Many of us usually interact day by day deploying, observing, etc. how our containerized applications and services in our case **OPENSHIFT** work, but several times these containers are not controlled, poorly deployed among other things that impact the health of the **OPENSHIFT** cluster.

For these scenarios in which we need to review a cluster in detail in an orderly manner or perhaps they give us access to a new **OPENSHIFT** cluster and ask us to validate that it is correctly configured and we only have access via the command line.

In these scenarios it is important to have a tool ready that allows us to obtain a snapshot of how our **OPENSHIFT** cluster is in order to analyze it and if it is in **REPORT** mode, much better.
<p> </p>
<p> </p>

**3. SOLUTION:**
We have worked on a **SCRIPT** .sh that unifies several good practices to analyze an **OPENSHIFT** Cluster, with the objective that every time it is required the generated **REPORT** is executed and saved.

This **Script** considers many validations and objective information in its commands in its execution, these are:

1. Authentication in OPENSHIFT.
2. Validation of information from the CLUSTER, the VERSION (CURRENT) & the VERSIONS. (AVAILABLE) in the CLUSTER.
3. Validation of NODES (MASTER/WORKER).
4. Validation of USERS & GROUPS.
5. Validation of PERSISTENT-VOLUME, PERSISTENT-VOLUME-CLAIN & STORAGE-CLASSES.
6. Validation of PERSISTENT-VOLUME (STORAGE) used by PODs.
7. Validation of OPERATORs (ASSETS).
8. Validation of PODs.
9. Validation of PODs in status: [PENDING/ERROR] (NOT READY).
10. Validation of DEPLOYMENTS & DEPLOYMENTCONFIGs.
11. Validation of SERVICEs & ROUTEs.
12. Validation of IMAGESTREAMs.
13. Validation of NETWORKPOLICIES.
14. Validation of CAPACITY & CONSUMPTION of RESOURCES [CPU/RAM].
15. Validation of CERTIFICATES (LOCATION & LIMITED DATE).
16. Validation of existence of MACHINES & MACHINECONFIGPOOL.
17. Validation of existence of: CERTIFICATE SIGNING REQUEST (CSR) in the CLUSTER (if APPROVED).
18. Validation of APP DEPLOYMENT.
19. SERVICE TEST Validation.
20. Cleaning RESOURCES created for the TEST.
<p> </p>
<p> </p>

**4. EJECUCIÓN:**
To make it work it would only be enough to:

**A.** Edit the Script: cluster-validator-report.sh
**B.** Execute:
` $ dos2unix cluster-validator-report.sh`
` $ chmod 777 cluster-validator-report.sh`
` $ sh ./cluster-validator-report.sh`
<p> </p>
<p> </p>

**5. IMAGES:**
Several images associated with the execution and result obtained are shared:

Start of **Script** where its header is explained:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/1.jpg?raw=true)
<p> </p>
<p> </p>
 
**Script** execution process:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/2.jpg?raw=true)
<p> </p>
<p> </p>

**Script** execution process:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/3.jpg?raw=true)
<p> </p>
<p> </p>
 
**Script** execution process:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/4.jpg?raw=true)
<p> </p>
<p> </p>

**Script** execution process:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/5.jpg?raw=true)
<p> </p>
<p> </p>

**Script** execution process:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/6.jpg?raw=true)
<p> </p>
<p> </p>

**REPORT** with execution results:
![alt text](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR/blob/main/IMAGES/7.jpg?raw=true)
<p> </p>
<p> </p>
 
**6. SOURCES:**
All fonts can be downloaded and reused here: [https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR.git](https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR.git "https://github.com/maktup/OPENSHIFT-CLUSTER-HEALTH-VALIDATOR.git")

