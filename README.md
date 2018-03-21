# Service Manager Specification


[![Build Status](https://travis-ci.org/Peripli/specification.svg?branch=master)](https://travis-ci.org/Peripli/specification)


## Table of Contents

 - [Notations and Terminology](#notations-and-terminology)
  - [Notational Conventions](#notational-conventions)
  - [Terminology](#terminology)
 - [Motivation](#motivation)
 - [How it works](#how-it-works)
 - [Concept details](#concept-details)
 - [API](#api)

## Notations and Terminology

### Notational Conventions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to
be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

### Terminology

This specification uses the terminology of the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/).

Additionally, this specification defines the following terms:

- *Platform Type*: A concrete implementation of a platform. Examples are Cloud Foundry and Kubernetes.

- *Platform Instance*: A deployment of a platform. For example, a Kubernetes cluster.

- *Cloud Landscape*: A collection of Platform Instances of the same or different types.
  In many cases, a Cloud Landscape is operated by one cloud provider,
  but the services may be also consumable by platforms outside the landscape.

- *Service Manager*: A component that acts as a platform as per OSB API and exposes a platform API.
  It allows the management and registration of service brokers and platform instances.
  Also acts as a central service broker.

- *Service Broker Proxy*:	A component that is associated with a platform that is registered at the Service Manager
  and is a service broker as per the OSB API specification.
  The proxy replicates the changes in the Service Manager into the platform instance in which the proxy resides.
  Service Brokers Proxies are in charge of registering and deregistering themselves at the platform it is responsible for.

## Motivation 

With Cloud Landscapes becoming bigger and more diverse, managing services is getting more difficult and new challenges arise:

 * Cloud providers are facing an increasing number of Platform Types, Platform Instances, supported IaaS and regions.
 At the same time, the number of services is increasing.
 Registering and managing a big amount of service brokers at a huge number of Platform Instances is infeasible.
 A central, Platform Instance independent component is needed to allow a sane management of service brokers.
 * So far, service instances are only accessible in the silo (platform) where they have been created. 
 But there are use-cases that require sharing of a service instance across platforms.
 For example, a database created in Kubernetes should be accessible in Cloud Foundry. 
 
A standardized way is needed for managing broker registrations and propagating them
to the registered Platform Instances when necessary. Also there should be a mechanism for tracking service instances creation
that allows sharing of service instances across Platform Instances.

## How it works

The Service Manager consists of multiple parts.
The main part is the core component.
It is the central registry for service broker and platform registrarion, as well as for tracking all service instances.
This core component communicates with the registered brokers and acts as a platform per OSB for them.

In each Platform Instance resides a component called the Service Broker Proxy.
It is the substitute for all brokers registered at the Service Manager
in order to replicate broker registration and access visibility changes in the corresponding Platform Instance.

When a broker is registered or deregistered at the Service Manager,
the Service Broker Proxy registers or deregisters itself in the name of this service broker.
From a Platform Instance point of view, the broker proxy is indistinguishable from the real broker because both implement the OSB API.

When the Platform Instance makes a call to the service broker, for example to provision a service instance,
the broker proxy accepts the call, forwards it to the Service Manager, which in turn forwards it to the real broker.
The response follows the same path back to the Platform Instance.
Because all OSB calls go through the Service Manager, it can track all service instances and share them between Platform Instances.

## Concept Details
Concept page to be added here.

## API

[API Specification](./api.md)
