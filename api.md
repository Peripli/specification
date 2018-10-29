
# Service Manager API

## Table of Contents

  - [Overview](#overview)
  - [Platform Management](#platform-management)
    - [Registering a Platform](#registering-a-platform)
    - [Fetchhing a Platform](#fetching-a-platform)
    - [Listing Platforms](#listing-platforms)
    - [Updating a Platform](#updating-a-platform)
    - [Deleting a Platform](#deleting-a-platform)
  - [Service Broker Management](#service-broker-management)
    - [Registering a Service Broker](#registering-a-service-broker)
    - [Fetching a Service Broker](#fetchhing-a-service-broker)
    - [Listing Service Brokers](#listing-service-brokers)
    - [Updating a Service Broker](#updating-a-service-broker)
    - [Deleting a Service Broker](#deleting-a-service-broker)
  - [Information](#information)
  - [OSB Management](#osb-management)
  - [Service Instance Management](#service-instance-management)
    - [Provisioning a Service Instance](#provisioning-a-service-instance)
    - [Fetching a Service Instance](#fetchhing-a-service-instance)
    - [Listing Service Instances](#listing-service-instances)
    - [Updating a Service Instance](#updating-a-service-instance)
    - [Deleting a Service Instance](#deleting-a-service-instance)
  - [Service Binding Management](#service-binding-management)
    - [Creating a Service Binding](#creating-a-service-binding)
    - [Fetching a Service Binding](#fetchhing-a-service-binding)
    - [Listing Service Binding](#listing-service-bindings)
    - [Updating a Service Binding](#updating-a-service-binding)
    - [Deleting a Service Binding](#deleting-a-service-binding)
  - [Service Management](#service-management)
    - [Fetching a Service](#fetchhing-a-service)
    - [Listing Services](#listing-services)
  - [Service Plan Management](#service-plan-management)
    - [Fetching a Service Plan](#fetchhing-a-service-plan)
    - [Listing Service Plans](#listing-service-plans)
  - [Credentials Object](#credentials-object)
  - [State Object](#state-object)
  - [Labels Object](#labels-object)
  - [Errors](#errors)
  - [Content Type](#content-type)

## Overview

The Service Manager API defines an HTTP interface that allows the management of platforms, brokers, services, plans, service instances and service bindings from a central place. In general, the Service Manager API can be split into two groups - a Service Controller API that allows the management of platform resources (SM as a platform) and an OSB compliant API. The latter implements the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/) and allows the Service Manager to act as a broker.

One of the access channels to the Service Manager is via the `smctl` CLI. The API should play nice in this context.
A CLI-friendly string is all lowercase, with no spaces. Keep it short -- imagine a user having to type it as an argument for a longer command.

## Platform Management

## Registering a Platform

In order for a platform to be usable with the Service Manager, the Service Manager needs to know about the platforms existence. Essentially, registering a platform means that a new service broker proxy for this particular platform has been registered with the Service Manager.

### Request

#### Route

`POST /v1/platforms`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt"
}
```

| Request field | Type | Description |
| ------------- | ---- | ----------- |
| id  | string | ID of the platform. If provided, MUST be unique across all platforms registered with the Service Manager. |
| name* | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type* | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |

\* Fields with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if the platform was registered as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a platform with the same `id` or `name` already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt",
    "created_at": "2016-06-08T16:41:22Z",
    "updated_at": "2016-06-08T16:41:26Z",
    "credentials" : {
        "basic": {
            "username": "admin",
            "password": "secret"
        }
    }
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the platform. If not provided in the request, new ID MUST be generated. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| credentials* | [credentials](#credentials-object) | A JSON object that contains credentials which the service broker proxy (or the platform) MUST use to authenticate against the Service Manager. Service Manager SHOULD be able to identify the calling platform from these credentials. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

## Fetching a Platform

### Request

#### Route

`GET /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Platform Object

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt",
    "created_at": "2016-06-08T16:41:22Z",
    "updated_at": "2016-06-08T16:41:26Z"
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the platform. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

## Listing Platforms

### Request

#### Route

`GET /v1/platforms`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
  "platforms": [
    {
      "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
      "name": "cf-eu-10",
      "type": "cloudfoundry",
      "description": "Cloud Foundry on AWS in Frankfurt",
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    },
    {
      "id": "e031d646-62a5-4a50-9d8e-23165172e9e1",
      "name": "k8s-us-05",
      "type": "kubernetes",
      "description": "Kubernetes on GCP in us-west1",
      "created_at": "2016-06-08T17:41:22Z",
      "updated_at": "2016-06-08T17:41:26Z"
    }
  ]
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| platforms* | array of [platforms](#platform-object) | List of registered platforms. |

\* Fields with an asterisk are REQUIRED.

## Updating a Platform

### Request

`PATCH /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt"
}
```

| Request field | Type | Description |
| ------------- | ---- | ----------- |
| name | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the platform was updated as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a platform with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt",
    "created_at": "2016-06-08T16:41:22Z",
    "updated_at": "2016-06-08T16:41:26Z"
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the platform. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

## Deleting a Platform

### Request

`DELETE /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the platform was deleted as a result of this request. The expected response body is `{}`. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Service Broker Management

## Registering a Service Broker

Registering a broker in the Service Manager makes the services exposed by this service broker available to all Platforms registered in the Service Manager.
Upon registration, Service Manager fetches and validate the catalog from the service broker.

### Request

#### Route

`POST /v1/service_brokers`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ----- | ---------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "broker_url": "http://service-broker-url.com",
    "credentials": {
        "basic": {
            "username": "admin",
            "password": "secret"
        }
    },
    "metadata": {

    }
}
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| name* | string | A CLI-friendly name of the service broker. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all service brokers registered with the Service Manager. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url* | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials* | [credentials](#credentials-object) | MUST be a valid credentials object which will be used to authenticate against the service broker. |
| metadata | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

\* Fields with an asterisk are REQUIRED.

### Response

| Status | Description |
| ------ | ----------- |
| 201 Created | MUST be returned if the service broker was registered as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |
| 409 Conflict | MUST be returned if a service broker with the same `name` is already registered. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "created_at": "2016-06-08T16:41:26Z",
    "updated_at": "2016-06-08T16:41:26Z",
    "broker_url": "https://service-broker-url",
    "metadata": {

    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the service broker. MUST be unique across all service brokers registered with the Service Manager. If the same service broker is registered multiple times, each registration will get a different ID. |
| name*          | string | Name of the service broker. |
| description    | string | Description of the service broker. |
| broker_url*    | string | URL of the service broker. |
| created_at     | string | the time of creation in ISO-8601 format |
| updated_at     | string | the time of the last update in ISO-8601 format |
| metadata       | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

\* Fields with an asterisk are REQUIRED.

## Fetching a Service Broker

### Request

#### Route

`GET /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK      | MUST be returned upon successful retrieval of the service broker. The expected response body is below. |
| 404 Not Found | MUST be returned if a service broker with the specified ID does not exist. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

#### Service Broker Object

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "created_at": "2016-06-08T16:41:26Z",
    "updated_at": "2016-06-08T16:41:26Z",
    "broker_url": "https://service-broker-url",
    "metadata": {

    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the service broker. |
| name*          | string | Name of the service broker. |
| description    | string | Description of the service broker. |
| broker_url*    | string | URL of the service broker. |
| created_at     | string | the time of creation in ISO-8601 format |
| updated_at     | string | the time of the last update in ISO-8601 format |
| metadata | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

\* Fields with an asterisk are REQUIRED.

## Listing Service Brokers

### Request

#### Route

`GET /v1/service_brokers`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK      | MUST be returned upon successful retrieval of the service brokers. The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
  "brokers": [
    {
      "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
      "name": "service-broker-name",
      "description": "Service broker providing some valuable services",
      "created_at": "2016-06-08T16:41:26Z",
      "updated_at": "2016-06-08T16:41:26Z",
      "broker_url": "https://service-broker-url",
      "metadata": {

      }
    },
    {
      "id": "a62b83e8-1604-427d-b079-200ae9247b60",
      "name": "another-broker",
      "description": "More services",
      "created_at": "2016-06-08T17:41:26Z",
      "updated_at": "2016-06-08T17:41:26Z",
      "broker_url": "https://another-broker-url"
    }
  ]
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| brokers* | array of [service brokers](#service-broker-object) | List of registered service brokers. |

\* Fields with an asterisk are REQUIRED.

## Updating a Service Broker

Updating a service broker allows to change its properties.

Updating a service broker MUST trigger an update of the catalog of this service broker.

### Request

#### Route

`PATCH /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "broker_url": "http://service-broker-url.com",
    "credentials": {
        "basic": {
            "username": "admin",
            "password": "secret"
        }
    },
    "metadata": {

    }
}
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | A CLI-friendly name of the service broker. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all service brokers registered with the Service Manager. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials | [credentials](#credentials-object) | If provided, MUST be a valid credentials object which will be used to authenticate against the service broker. |
| metadata | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

All fields are OPTIONAL. Fields that are not provided MUST NOT be changed.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the requested changes have been applied. The expected response body is `{}` |
| 400 Bad Request | MUST be returned if the request is malformed or a forbidden modification attempt is made. |
| 409 Conflict | MUST be returned if a service broker with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "created_at": "2016-06-08T16:41:26Z",
    "updated_at": "2016-06-08T16:41:26Z",
    "broker_url": "https://service-broker-url",
    "metadata": {

    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the service broker. |
| name*          | string | Name of the service broker. |
| description    | string | Description of the service broker. |
| broker_url*    | string | URL of the service broker. |
| created_at     | string | the time of creation in ISO-8601 format |
| updated_at     | string | the time of the last update in ISO-8601 format |
| metadata | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

\* Fields with an asterisk are REQUIRED.

## Deleting a Service Broker

When the Service Manager receives a delete request, it MUST delete any resources it created during registration of this service broker.

Deletion of a service broker for which there are Service Instances created MUST fail. This behavior can be overridden by specifying the `force` query parameter which will remove the service broker regardless of whether there are Service Instances created by it.

### Request

#### Route

`DELETE /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| force | boolean | Whether to force the deletion of the service broker, ignoring existing Service Instances associated with it. |

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK      | MUST be returned upon successful deletion of the service broker. The expected response body is `{}`. |
| 400 Bad Request | Returned if the request is malformed or there are service instances associated with the service broker and `force` parameters is not `true`. |
| 404 Not Found | MUST be returned if a service broker with the specified ID does not exist. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Information

The Service Manager exposes publicly available information that can be used when accessing its APIs.

### Request

#### Route

`GET /v1/info`

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned upon successful processing of this request. The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

```json
{
    "token_issuer_url": "https://example.com"
}
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_issuer_url* | string | URL of the token issuer. The token issuer MUST have a public endpoint `/.well-known/openid-configuration` as specified by the [OpenID Provider Configuration](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig) |

\* Fields with an asterisk are REQUIRED.

## Service Instance Management

### Provisioning a Service Instance

### Request

#### Route

`POST /v1/service_instances`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{  
  "name": "my-service-instance",
  "plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
        "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  }
}
```

### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created     | MUST be returned if the resource was created. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict    | MUST be returned if a resource with the same `name` already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Instance Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-instance",
  "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  },
  "state": {  
    "ready": "False",
    "reasons": [
      "LastOperationSucceeded"
    ],
    "message": "Service Binding is currently being created",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "False",
        "reason": "InProgess",
        "message": "Create deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 is still in progress",
        "name": "Create"
      },
      {  
        "type": "OrphanMitigationRequired",
        "status": "False",
        "reason": "ServiceBrokerResponseSuccess",
        "message": "Service Broker returned 202 Accepted for PUT https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

### Fetching a Service Instance

### Request

#### Route

`GET /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Instance Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-instance",
  "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  },
  "state": {  
    "ready": "True",
    "reasons": [  

    ],
    "message": "Service Binding is ready for use",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "True",
        "reason": "Completed",
        "message": "Create deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 succeeded at 2018-09-26T07:43:36.000Z",
        "name": "Create"
      },
      {  
        "type": "OrphanMitigationRequired",
        "status": "True",
        "reason": "ServiceBrokerTimeout",
        "message": "Service Broker request timeout: PUT https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

###  Listing Service Instances

### Request

#### Route

`GET /v1/service_instances`

#### Parameters

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| page | int | page of items to fetch. |
| pageSize | int | number of items per page. If not provided, defaults to 50. |
| labelQuery | string | Filter the response based on the label query. Only items that have labels matching the provided label query will be returned. If present, MUST be a non-empty string. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |

    Example: `GET /v1/service_instances?labelQuery=context_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service instances that have a label `context_id` that has a value `bvsded31-c303-123a-aab9-8crar19e1218`.
    
    Example: `GET /v1/service_instances?fieldQuery=service_plan_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service instances for the plan with ID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce creation is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{  
  "total_results": 1,
  "total_pages": 1,
  "next_url": "",
  "prev_url": "",
  "items": [  
    {  
      "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "my-service-instance",
      "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
      "parameters": {  
        "parameter1": "value1",
        "parameter2": "value2"
      },
      "labels": {  
        "context_id": [
          "bvsded31-c303-123a-aab9-8crar19e1218"
        ]
      },
      "state": {  
        "ready": "True",
        "reasons": [  

        ],
        "message": "Service Binding is currently being deleted",
        "conditions": [  
          {  
            "type": "LastOperationSucceeded",
            "status": "True",
            "reason": "Completed",
            "message": "Create deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 succeeded at 2018-09-26T07:43:36.000Z",
            "name": "Create"
          },
          {  
            "type": "OrphanMitigationRequired",
            "status": "False",
            "reason": "ServiceBrokerResponseSuccess",
            "message": "Service Broker returned 202 Accepted for PUT https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114"
          }
        ]
      },
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

### Updating a Service Instance

### Request

`PATCH /v1/service_instances/:service_instance_id`

`:service_instance_id` The ID of a previously provisioned service instance.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{  
  "name": "new-instance-name",
  "parameters": {  
    "parameter1": "value1"
  },
  "labels": [
    { "op": "add", "key": "label1", "values": ["test1", "test2"] },
    { "op": "add_value", "key": "label2", "values": ["test3"] },
    { "op": "replace", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label2" },
    { "op": "remove_value", "key": "label1", "values": ["test2"] }
  ]  
}
```

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed. If provided, `parameters` will override the old values.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce update is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Instance Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "new-instance-name",
  "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "parameters": {  
    "parameter1": "value1"
  },
  "labels": {  
    "label1": [
      "value1"
    ]
  },
  "state": {  
    "ready": "False",
    "reasons": [  
      "LastOperationSucceeded"
    ],
    "message": "Service Instance is currently being updated",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "False",
        "reason": "InProcess",
        "message": "Updating deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
        "name": "Update"
      },
      {  
        "type": "OrphanMitigationRequired",
        "status": "False",
        "reason": "ServiceBrokerResponseSuccess",
        "message": "Service Broker returned 202 Accepted for PATCH https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2018-06-08T16:41:26Z"
}
```

\* Fields with an asterisk are REQUIRED.

### Deleting a Service Instance

### Request

`DELETE /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| force | boolean | Whether to force the deletion of the resource and all asociated resources from Service Manager. No call to the actual Service Broker is performed. |


#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce deletion is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted. The expected response body is `{}`. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or there are service bindings associated with the service instance and `force` is not `true`. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Service Binding Management

### Creating a Service Binding

### Request

#### Route

`POST /v1/service_bindings`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{  
  "name": "my-service-binding",
  "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  }
}
```

\* Fields with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if a resouce creation is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with the same `id` or `name` already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Binding Object

```json
{  
  "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
  "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
  "credentials": {  
    "creds-key-63": "creds-val-63"
  },
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  },
  "state": {  
    "ready": "False",
    "reasons": [  
      "LastOperationSucceeded"
    ],
    "message": "Service Binding is currently being deleted",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "False",
        "reason": "InProgess",
        "message": "Delete deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 is still in progress",
        "name": "Delete"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

### Fetching a Service Binding

### Request

`GET /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | -----| ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Binding Object

```json
{  
  "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
  "name": "my-service-binding",
  "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
  "credentials": {  
    "creds-key-63": "creds-val-63"
  },
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  },
  "state": {  
    "ready": "False",
    "reasons": [  
      "OrphanMitigationRequired"
    ],
    "message": "Service Binding is currently being deleted",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "True",
        "reason": "Completed",
        "message": "Create deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 succeeded at 2018-09-26T07:43:36.000Z",
        "name": "Create"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

### Listing Service Bindings

### Request

#### Route

`GET /v1/service_bindings`

#### Parameters

The request provides these query string parameters as useful hints for brokers.

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| page | int | page of items to fetch. |
| pageSize | int | number of items per page. If not provided, defaults to 50. |
| labelQuery | string | Filter the response based on the label query. Only items that have labels matching the provided label query will be returned. If present, MUST be a non-empty string. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |

    Example: `GET /v1/service_bindings?labelQuery=context_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service bindings that have a label `context_id` that has a value `bvsded31-c303-123a-aab9-8crar19e1218`.
    
    Example: `GET /v1/service_bindings?fieldQuery=service_instance_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service bindings for the service instance with ID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce creation is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{  
  "total_results": 1,
  "total_pages": 1,
  "next_url": "",
  "prev_url": "",
  "items": [  
    {  
      "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
      "name": "my-service-binding",
      "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
      "credentials": {  
        "creds-key-63": "creds-val-63"
      },
      "parameters": {  
        "parameter1": "value1",
        "parameter2": "value2"
      },
      "labels": {  
        "context_id": [
          "bvsded31-c303-123a-aab9-8crar19e1218"
        ]
      },
      "state": {  
        "ready": "True",
        "reasons": [  
          "LastOperationSucceeded"
        ],
        "message": "Service Binding is currently being deleted",
        "conditions": [  
          {  
            "type": "LastOperationSucceeded",
            "status": "True",
            "reason": "Completed",
            "message": "Update deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 succeeded at 2018-09-26T07:43:36.000Z",
            "name": "Update"
          }
        ]
      },
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

### Updating a Service Binding

### Request

`PATCH /v1/service_bindings/:service_binding_id`

`:service_binding_id` The ID of a previously created service binding.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

#### Body

```json
{  
  "name": "new-binding-name",
  "parameters": {  
    "parameter1": "newval"
  },
  "labels": [
    { "op": "add", "key": "label1", "values": ["test1", "test2"] },
    { "op": "add_value", "key": "label2", "values": ["test3"] },
    { "op": "replace", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label2" },
    { "op": "remove_value", "key": "label1", "values": ["test2"] }
  ]  
}
```

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed. If provided, `parameters` will override the old values.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce update is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Binding Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "new-binding-name",
  "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "credentials": {  
    "creds-key-63": "creds-val-63"
  },
  "parameters": {  
    "parameter1": "newval"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ],
    "label1": [
      "value1"
    ]
  },
  "state": {  
    "ready": "False",
    "reasons": [  
      "LastOperationSucceeded"
    ],
    "message": "Service Binding is currently being deleted",
    "conditions": [  
      {  
        "type": "LastOperationSucceeded",
        "status": "False",
        "reason": "InProcess",
        "message": "Updating deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
        "name": "Update"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2018-06-08T16:41:26Z"
}
```

\* Fields with an asterisk are REQUIRED.


### Deleting a Service Binding

### Request

`DELETE /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| force | boolean | Whether to force the deletion of the resource and all asociated resources from Service Manager. No call to the actual Service Broker is performed. |


#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce deletion is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted. The expected response body is `{}`. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or there are service bindings associated with the service instance and `force` is not `true`. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Service Management

### Fetching a Service

### Request

#### Route

`GET /v1/services/:service_id`

`:service__id` MUST be the ID of a previously created service.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Object

```json
{  
  "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service",
  "description": "service description",
  "displayName": "postgres",
  "longDescription": "local postgres",
  "service_broker_id": "0e7250aa-364f-42c2-8fd2-808b0224376f",
  "bindable": true,
  "plan_updateable": false,
  "instances_retrievable": false,
  "bindings_retrievable": false,
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

### Listing Services

### Request

#### Route

`GET /v1/services`

#### Parameters

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| page | int | page of items to fetch. |
| pageSize | int | number of items per page. If not provided, defaults to 50. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |
    
    Example: `GET /v1/services?fieldQuery=service_broker_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service  for the servie broker with GUID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce creation is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{  
  "total_results": 1,
  "total_pages": 1,
  "next_url": "",
  "prev_url": "",
  "items":[  
    {  
      "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "my-service",
      "description": "service description",
      "displayName": "display-name",
      "longDescription": "long-name",
      "service_broker_id": "0e7250aa-364f-42c2-8fd2-808b0224376f",
      "bindable": true,
      "plan_updateable": false,
      "instances_retrievable": false,
      "bindings_retrievable": false,
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

## Service Plan Management

### Fetching a Service Plan

### Request

#### Route

`GET /v1/plans/:plan_id`

`:plan_id` MUST be the ID of a previously created plan.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Service Plan Object

```json
{  
  "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "plan-name",
  "free": false,
  "description": "description",
  "service_id": "1ccab853-87c9-45a6-bf99-603032d17fe5",
  "extra": null,
  "unique_id": "1bc2884c-ee3d-4f82-a78b-1a657f79aeac",
  "public": true,
  "active": true,
  "bindable": true,
  "schemas": {  
    "service_instance": {  
      "create": {  

      },
      "update": {  

      }
    },
    "service_binding": {  
      "create": {  

      }
    }
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

\* Fields with an asterisk are REQUIRED.

### Listing Service Plans

### Request

#### Route

`GET /v1/plans`

#### Parameters

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| page | int | page of items to fetch. |
| pageSize | int | number of items per page. If not provided, defaults to 50. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |
    
    Example: `GET /v1/plans?fieldQuery=service_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service plans for the service with GUID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if a resouce creation is performed as a result of this request. This would imply that the Service Broker returned 200 OK or 202 Accepted.The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{  
  "total_results": 1,
  "total_pages": 1,
  "next_url": "",
  "prev_url": "",
  "items": [  
    {  
      "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "plan-name",
      "free": false,
      "description": "description",
      "service_id": "1ccab853-87c9-45a6-bf99-603032d17fe5",
      "extra": null,
      "unique_id": "1bc2884c-ee3d-4f82-a78b-1a657f79aeac",
      "public": true,
      "active": true,
      "bindable": true,
      "schemas": {  
        "service_instance": {  
          "create": {  

          },
          "update": {  

          }
        },
        "service_binding": {  
          "create": {  

          }
        }
      },
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

## Service Visibilities Management

There are currently ongoing dicussions as to how platform and service visilibities should be handled in  SM.
TODO: Add content here.

## OSB Management

The OSB Management API is an implementation of v2.13 of the [OSB API specification](https://github.com/openservicebrokerapi/servicebroker). It enables the Service Manager to act as a central service broker and be registered as one in the  platforms that are associated with it (meaning the platforms that are registered in the Service Manager). The Service Manager also takes care of delegating the OSB calls to the registered brokers (meaning brokers that are registered in the Service Manager) that should process the request. As such, the Service Manager acts as a platform for the actual (registered) brokers.

### Request 

The OSB Management API prefixes the routes specified in the OSB spec with `/v1/osb/:broker_id`.

`:broker_id` is the id of the broker that the OSB call is targeting. The Service Manager MUST forward the call to this broker. The `broker_id` MUST be a globally unique non-empty string.

When a request is send to the OSB Management API, after forwarding the call to the actual broker but before returning the response, the Service Manager MAY alter the body of the response. For example, in the case of `/v1/osb/:broker_id/v2/catalog` request, the Service Manager MAY, amongst other things, add additional plans (reference plan) to the catalog.

In its role of a platform for the registered brokers, the Service Manager MAY define its own format for `Context Object` and `Originating Identity Header` similar but not limited to those specified in the [OSB spec profiles page](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md).

## Credentials Object

This specification does not limit how the Credentials Object should look like as different authentication mechanisms can be used. Depending on the used authentication mechanism, additional fields holding the actual credentials MAY be included.

| Field | Type | Description |
| ----- | ---- | ----------- |
| basic | [basic credentials](#basic-credentials-object) | Credentials for basic authentication |
| token | string | Bearer token |

_Exactly_ one of the properties `basic` or `token` MUST be provided.

### Basic Credentials Object

| Field | Type | Description |
| ----- | ---- | ----------- |
| username* | string | username |
| password* | string | password |

\* Fields with an asterisk are RENQUIRED.

## State Object

Resources that support asynchronous creation, deletion and updates MUST contain a `state` object.

| Field | Type | Description |
| ----- | ---- | ----------- |
| ready* | boolean | Indicates whether a resource is ready for use or not |
| conditions* | array of [conditions](#conditions-object) | Describe the state of the resource and indicate what actions should be taken in order for the resource to become ready |
| reasons* | array of strings | A subset of the types of the `conditions` that are relevant to why the `ready` field is what it is |
| message* | string | Human-readable summary for the reasoning behind the `ready` being what it is |

### Conditions Object

The `conditions` describe the current conditions in which the resource is. 
Each resource MAY add specific conditions and should also handle those conditions accordingly in case they sum up to an undesired `state` (in most cases this would be a `ready: false` state).
Each `condition` MAY include additional fields apart from those specified below in order to provide meaningful information.


| Field | Type | Description |
| ----- | ---- | ----------- |
| type* | string | The type of the condition |
| status* | boolean | Used to determine whether any actions should be taken in regards of this condition. For example, a condition of type operation with status false would imply that the operation is still in progress |
| message* | string | Human-readable details that describe the condition |
| reason* | string | A single word containing the reason for the condition status |

In order to maintain the state up to date, each resource that contains a `state` MUST also expose APIs for retrieving and updating it. 

### Fetchhing the state of a resource

### Request

#### Route

`GET /v1/:resource/:resource_id/state`

`:resource` is a resource that has a state (for example service_instances)

`:resource_id` MUST be the ID of a previously created resource.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`). It contains the [state object](#state-object) for this resource.

Example state:

```json
{  
  "ready": "True",
  "reasons": [  
    "LastOperationSucceeded", ...
  ],
  "message": "Resource is currently being deleted",
  "conditions": [  
    {  
      "type": "LastOperationSucceeded",
      "status": "True",
      "reason": "Completed",
      "message": "Successfully updated resource r-0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
      "name": "Update"
    },
    ...
  ]
}
```

## Labels Object

A label is a key-value pair that can be attached to a resource. Service Manager resources MAY have any number of labels.

This allows querying (filtering) on the `List` API of the resource based on multiple labels. The Service Manager MAY
attach additional labels to the resources and MAY restrict updates and deletes for some of the labels.

Example:

```json
{  
  "label1Key": [
    "label1Value"
  ],
  "label2Key": [
    "label2Value1"
  ]
}
```

### Patching Labels

The PATCH APIs of the resources that support labels MUST support the following `label operations` in order to update labels and label values.

| Operation | Description |
| --------- | ----------- |
| add | Adds a new label with the name in `label`. The `value` MUST be a string or an array of strings. If the label already exists, the operation fails. |
| add_value | Appends a new value to a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails. |
| replace | Replaces a label with new values. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails. |
| replace_value | Replaces a value in a label. The `value` MUST be a string. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails. |
| remove_label | Removes a label. If the label does not exist, the operation fails. |
| remove_values | Removes a value from a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails |

If one operations fails, none of the changes will be applied.

Example: PATCH v1/:resource/:resource_id/ with body:

```
...
"labels": [
    { "op": "add", "key": "label1", "values": ["test1", "test2"] },
    { "op": "add_value", "key": "label2", "values": ["test3"] },
    { "op": "replace", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label2" },
    { "op": "remove_value", "key": "label1", "values": ["test2"] }
  ]
...  
```

## Errors

When a request to the Service Manager fails, it MUST return an
appropriate HTTP response code. Where the specification defines the expected
response code, that response code MUST be used.

The response body MUST be a valid JSON Object (`{}`).
For error responses, the following fields are defined. The Service Manager MAY
include additional fields within the response.

| Response Field | Type | Description |
| --- | --- | --- |
| error | string | A single word that uniquely identifies the error condition. If present, MUST be a non-empty string with no whitespace. It MAY be used to identify the error programmatically on the client side. |
| description | string | A user-facing error message explaining why the request failed. If present, MUST be a non-empty string. |

Example:
```json
{
  "error": "InvalidCredentials",
  "description": "The supplied credentials could not be authorized"
}
```

## Content Type

All requests and responses defined in this specification with accompanying bodies SHOULD contain a `Content-Type` header set to `application/json`. If the `Content-Type` is not set, Service Brokers and Platforms MAY still attempt to process the body. If a Service Broker rejects a request due to a mismatched Content-Type or the body is unprocessable it SHOULD respond with `400 Bad Request`.