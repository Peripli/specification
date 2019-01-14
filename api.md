
# Service Manager API

## Table of Contents

  - [Overview](#overview)
  - [Platform Management](#platform-management)
    - [Registering a Platform](#registering-a-platform)
    - [Retrieving a Platform](#retrieving-a-platform)
    - [Retrieving All Platforms](#retrieving-all-platforms)
    - [Deleting a Platform](#deleting-a-platform)
    - [Updating a Platform](#updating-a-platform)
  - [Service Broker Management](#service-broker-management)
    - [Registering a Service Broker](#registering-a-service-broker)
    - [Retrieving a Service Broker](#retrieving-a-service-broker)
    - [Retrieving All Service Brokers](#retrieving-all-service-brokers)
    - [Deleting a Service Broker](#deleting-a-service-broker)
    - [Updating a Service Broker](#updating-a-service-broker)
  - [Visibility Management](#visibility-management)
    - [Creating a Visibility](#creating-a-visibility)
    - [Retrieving a Visibility](#retrieving-a-visibility)
    - [Retrieving All Visibilities](#retrieving-all-visibilities)
    - [Deleting a Visibility](#deleting-a-visibility)
    - [Updating a Visibility](#updating-a-visibility)
  - [Labels](#labels)
    - [Syntax](#syntax)
    - [Label Management](#label-management)
        - [Attaching Labels](#attaching-labels)
        - [Detaching Labels](#detaching-labels)
        - [Adding Label Values](#adding-label-values)
        - [Removing Label values](#removing-label-values)
    - [Label Change Object](#label-change-object)
  - [Information](#information)
  - [Service Management](#service-management)
  - [Credentials Object](#credentials-object)
  - [Errors](#errors)
  - [Content Type](#content-type)

## Overview

The Service Manager API defines an HTTP interface that allows the management of platforms, brokers and services from a central place. In general, the Service Manager API can be split into two groups - a Service Controller API that allows the management of platforms and service brokers and an OSB compliant API. The latter implements the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/) and allows the Service Manager to act as a broker.

One of the access channels to the Service Manager is via a CLI. The API should play nice in this context.
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
| --- | --- | --- |
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
| --- | --- | --- |
| id  | string | ID of the platform. If provided, MUST be unique across all platforms registered with the Service Manager. |
| name* | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type* | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |

\* Fields with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| --- | --- |
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
| --- | --- | --- |
| id* | string | ID of the platform. If not provided in the request, new ID MUST be generated. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| credentials* | [credentials](#credentials-object) | A JSON object that contains credentials which the service broker proxy (or the platform) MUST use to authenticate against the Service Manager. Service Manager SHOULD be able to identify the calling platform from these credentials. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

## Retrieving a Platform

### Request

#### Route

`GET /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| --- | --- |
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
| --- | --- | --- |
| id* | string | ID of the platform. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

## Retrieving All Platforms

### Request

#### Route

`GET /v1/platforms`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| --- | --- |
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
| --- | --- | --- |
| platforms* | array of [platforms](#platform-object) | List of registered platforms. |

\* Fields with an asterisk are REQUIRED.

## Deleting a Platform

### Request

`DELETE /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| --- | --- |
| 200 OK | MUST be returned if the platform was deleted as a result of this request. The expected response body is `{}`. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Updating a Platform

### Request

`PATCH /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered platform.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
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
| --- | --- | --- |
| name | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed.

### Response

| Status Code | Description |
| --- | --- |
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
| --- | --- | --- |
| id* | string | ID of the platform. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| created_at | string | The time of the creation in ISO-8601 format |
| updated_at | string | The time of the last update in ISO-8601 format |

\* Fields with an asterisk are REQUIRED.

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
| --- | --- | --- |
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
| metadata | object | Additional data associated with the service broker. This JSON object MAY have arbitrary content. |

\* Fields with an asterisk are REQUIRED.

## Retrieving a Service Broker

### Request

#### Route

`GET /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
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

## Retrieving All Service Brokers

### Request

#### Route

`GET /v1/service_brokers`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
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
| --- | --- | --- |
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
| --- | --- | --- |
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

## Visibility Management

Visibilities in the Service Manager are used to manage which platform sees which service plan. If applicable, labels MAY be attached to a visibility to further scope the access of the plan inside the platform.

## Creating a Visibility

### Route
`POST /v1/visibilities`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Request Body
```json
{
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "labels": {
        "label1": ["value1"]
    }
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| platform_id | string | If present, MUST be the ID of an existing Platform. If missing, this means that the plan is visible to all platforms. |
| service_plan_id* | string | MUST be the ID of an existing Service Plan. |
| labels | labels object | MUST be a valid labels object |

\* Fields with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if the visibility was created as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the visibility is invalid. An invalid visibility is one where either the platform_id or service_plan_id do not exist, or a visibility for this service_plan_id already exists, but with an empty platform_id. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a visibility for this platform_id and service_plan_id already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "labels": {
        "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the visibility. |
| platform_id          | string | ID of the Platform for this visibility. |
| service_plan_id*    | string | ID of the Service plan for this visibility. |
| labels    | [Labels object](#labels-object) | Labels for this visibility. |

\* Fields with an asterisk are REQUIRED.

## Retrieving a Visibility

### Request

#### Route

`GET /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created visibility

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution was successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested visibility is missing. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

##### Visibility Object
```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "labels": {
        "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the visibility. |
| platform_id      | string | ID of the Platform for this visibility. |
| service_plan_id* | string | ID of the Service plan for this visibility. |
| labels    | [Labels](#labels) object | Labels for this visibility. |

\* Fields with an asterisk are REQUIRED.

## Retrieving All Visibilities

### Request

#### Route

`GET /v1/visibilities`

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution was successful. The expected response body is below. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "visibilities": [
        {
            "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
            "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
            "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
            "labels": {
                "label1": ["value1"]
            }
        },
        {
            "id": "fbb0692a-76f3-42f6-b537-58b1be7ec618",
            "platform_id": "e031d646-62a5-4a50-9d8e-23165172e9e1",
            "service_plan_id": "acsded31-c303-123a-aab9-8crar19e1218",
            "labels": {
                "label2": ["value2"]
            }
        }
    ]
    
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| visibilities*  | array of [visibilities](#visibility-object) | List of existing visibilities. |

\* Fields with an asterisk are REQUIRED.

## Deleting a Visibility

### Request

#### Route

`DELETE /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created visibility

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution was successful. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested visibility is missing. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body is `{}`.

## Updating a Visibility

### Route
`PATCH /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created visibility

#### Headers

The following HTTP Headers are defined for this operation:

| Header | Type | Description |
| --- | --- | --- |
| Authorization* | string | Provides a means for authentication and authorization |

\* Headers with an asterisk are REQUIRED.

### Request Body
```json
{
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "labels": [
        {
            "op": "add",
            "key": "label2",
            "values": ["value2", "value3"]
        }
    ]
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| platform_id | string | If present, MUST be the ID of an existing Platform. |
| service_plan_id | string | If present, MUST be the ID of an existing Service Plan. |
| labels | array of [Label Change objects](#label-change-object) | MUST be a valid array of label changes |

\* Fields with an asterisk are REQUIRED.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the visibility was updated as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the visibility update is invalid. An invalid visibility update is one where either the platform_id or service_plan_id do not exist, or a visibility for this service_plan_id already exists, but with an empty platform_id, or the label changes are invalid. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested visibility is missing. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "labels": {
        "label1": ["value1"],
        "label2": ["value2", "value3"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the visibility. |
| platform_id      | string | ID of the Platform for this visibility. |
| service_plan_id* | string | ID of the Service plan for this visibility. |
| labels    | [Labels](#labels) object | Labels for this visibility calculated after the update. |

\* Fields with an asterisk are REQUIRED.

## Labels

Specific resources in the Service Manager MAY be labeled in order to be organized into groups relevant to the users.  
This specification does not limit which resources MUST be labeled. However, all resources that might benefit from having labels, are presented in ther extended form contaning labels.

### Syntax

Labels MUST consist of one or more keys, where each key MUST be mapped to a list of values.  

This specification does not restrict the allowed character set, length of keys and values or reserved/mandatory keys per resource.

##### Labels Object
```json
{
    ...
    "labels": {
        "key1": ["value1", "value2"],
        "key2": ["value3", "value4"]
    }
}
```

### Label Management

### Attaching Labels

Labels SHOULD be attached to a resource at [creation time](#when-creating-a-resource), or later by [updating](#when-updating-a-resource) the respective resource.

#### When creating a resource

### Route
`POST /v1/:resource_type`

`:resource_type` MUST be a valid Service Manager resource type. 

### Request Body
```json
{
    ...
    "labels": {
        "label1": ["value1"]
    }
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| labels* | [labels object](#labels-object) | MUST be a valid labels object |

\* Fields with an asterisk are REQUIRED.

### Response

Each `resource type` decides on the returned response statuses.  
Below are the statuses that are recommended when attaching a label at creation time.

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if the labels were created as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the labels have invalid syntax. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

#### Body

The response body MUST be a valid JSON Object (`{}`).  
The labels MUST be returned as part of the response.

```json
{
    ...
    "labels": {
        "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| labels*    | [Labels](#labels) object | Labels for this resource. |

\* Fields with an asterisk are REQUIRED.


#### When updating a resource

### Route
`PATCH /v1/:resource_type/:resource_id`

`:resource_type` MUST be a valid Service Manager resource type.  
`:resource_id` MUST be the ID of a previously created resource of this resource type.

### Request Body
```json
{
    ...
    "labels": [
        {
            "op": "add",
            "key": "label1",
            "values": ["value1", "value2"]
        }
    ]
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| labels* | array of [Label Change objects](#label-change-object) | MUST be a valid array of label changes |

\* Fields with an asterisk are REQUIRED.

### Response

Each `resource type` decides on the returned response statuses.  
Below are the statuses that are recommended when attaching a label.

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the labels were attached as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the label detachment is invalid. An invalid label detachment is one where either the label key has invalid syntax, or a label with such key was not previously attached to the resource. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|


#### Body

The response body MUST be a valid JSON Object (`{}`).  
The calculated labels MUST be returned as part of the response.

```json
{
    ...
    "labels": {
        "label1": ["value1", "value2"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| labels*    | [Labels](#labels) object | Labels for this resource. |

\* Fields with an asterisk are REQUIRED.

### Detaching Labels

Labels SHOULD be detached only by updating a resource.

### Route
`PATCH /v1/:resource_type/:resource_id`

`:resource_type` MUST be a valid Service Manager resource type.  
`:resource_id` MUST be the ID of a previously created resource of this resource type.

### Request Body
```json
{
    ...
    "labels": [
        {
            "op": "remove",
            "key": "label2"
        }
    ]
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| labels* | array of [Label Change objects](#label-change-object) | MUST be a valid array of label changes |

\* Fields with an asterisk are REQUIRED.

### Response

Each `resource type` decides on the returned response statuses.  
Below are the statuses that are recommended when detaching a label.

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the labels were detached as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the label detachment is invalid. An invalid label detachment is one where either the label key has invalid syntax, or a label with such key was not previously attached to the resource. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|


#### Body

The response body MUST be a valid JSON Object (`{}`).  
The calculated labels MUST be returned as part of the response.

```json
{
    ...
    "labels": {
        "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| labels*    | [Labels object](#labels-object) | Labels for this resource. |

\* Fields with an asterisk are REQUIRED.

### Adding Label Values

Label values SHOULD be added only by updating the resource that the label is attached to.

### Route
`PATCH /v1/:resource_type/:resource_id`

`:resource_type` MUST be a valid Service Manager resource type.  
`:resource_id` MUST be the ID of a previously created resource of this resource type.

### Request Body
```json
{
    ...
    "labels": [
        {
            "op": "add_values",
            "key": "label1",
            "values": ["value2", "value3"]
        }
    ]
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| labels* | array of [Label Change objects](#label-change-object) | MUST be a valid array of label changes |

\* Fields with an asterisk are REQUIRED.

### Response

Each `resource type` decides on the returned response statuses.  
Below are the statuses that are recommended when adding new values to a label.

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the values were added to the label with the specified key as a result of this request. If a label with such key is not attached to the resource, it SHOULD be created and attached to the resource. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the label change is invalid. An invalid add-values label change is one where either the label key and/or values have invalid syntax, or one or more of the values are already mapped to a label with this key. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

#### Body

The response body MUST be a valid JSON Object (`{}`).  
The calculated labels MUST be returned as part of the response.

```json
{
    ...
    "labels": {
        "label1": ["value1", "value2", "value3"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| labels*    | [Labels object](#labels-object) | Labels for this resource. |

\* Fields with an asterisk are REQUIRED.

### Removing Label Values

Label values SHOULD be removed only by updating the resource that the label is attached to.

### Route
`PATCH /v1/:resource_type/:resource_id`

`:resource_type` MUST be a valid Service Manager resource type.  
`:resource_id` MUST be the ID of a previously created resource of this resource type.

### Request Body
```json
{
    ...
    "labels": [
        {
            "op": "remove_values",
            "key": "label1",
            "values": ["value2"]
        }
    ]
}
```
| Name | Type | Description |
| ---- | ---- | ----------- |
| labels* | array of [Label Change objects](#label-change-object) | MUST be a valid array of label changes |

\* Fields with an asterisk are REQUIRED.

### Response

Each `resource type` decides on the returned response statuses for this resource.  
Below are the statuses that are recommended when remove values from a label.

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the values were remove from the label with the specified key as a result of this request. The expected response body is below. |
| 400 Bad Request | MUST be returned if the request is malformed, missing mandatory data or the label change is invalid. An invalid remove-values label change is one where either the label key and/or values have invalid syntax, one or more of the values were not mapped to a label with this key, or a label with this key is not attached to the resource. The description field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

#### Body

The response body MUST be a valid JSON Object (`{}`).  
The calculated labels MUST be returned as part of the response.

```json
{
    ...
    "labels": {
        "label1": ["value1", "value2", "value3"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| labels*    | [Labels object](#labels-object) | Labels for this resource. |

\* Fields with an asterisk are REQUIRED.

## Label Change Object

Each change of a label MUST be performed by passing a label change object, which is a JSON-Patch-like object that allows for modification of existing labels and attaching new labels to resources.

| Field | Type | Description |
| --- | --- | --- |
| op* | [label change operation](#label-change-operation) | Operation for updating the label change |
| key* | string | Key of the label to be changed |
| values* | array of strings | Values to be changed |

\* Field MAY be required depending on the [label change operation](#label-change-operation).

### Label Change Operation

This specification does not limit the operations, but these are the minimum set of operations that MUST be supported.

| Operation | Description |
| --------- | ----------- |
| add | Adds a new label with the specified key and values. All fields are required. |
| add_values | Appends new values to the label with the specified key. All fields are required. |
| remove | Removes the label with the specified key. `values` field is optional. `op` and `key` fields are required. |
| remove_values | Removes the values from the label with the specified key. All fields are required. |


## Information

The Service Manager exposes publicly available information that can be used when accessing its APIs.

### Request

#### Route

`GET /v1/info`

### Response

| Status Code | Description |
| --- | --- |
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


## Service Management

The Service Management API is an implementation of v2.13 of the [OSB API specification](https://github.com/openservicebrokerapi/servicebroker). It enables the Service Manager to act as a central service broker and be registered as one in the  platforms that are associated with it (meaning the platforms that are registered in the Service Manager). The Service Manager also takes care of delegating the OSB calls to the registered brokers (meaning brokers that are registered in the Service Manager) that should process the request. As such, the Service Manager acts as a platform for the actual (registered) brokers.

The Service Management API prefixes the routes specified in the OSB spec with `/v1/osb/:broker_id`.

`:broker_id` is the id of the broker that the OSB call is targeting. The Service Manager MUST forward the call to this broker. The `broker_id` MUST be a globally unique non-empty string.

When a request is send to the Service Management API, after forwarding the call to the actual broker but before returning the response, the Service Manager MAY alter the body of the response. For example, in the case of `/v1/osb/:broker_id/v2/catalog` request, the Service Manager MAY, amongst other things, add additional plans (reference plan) to the catalog.

In its role of a platform for the registered brokers, the Service Manager MAY define its own format for `Context Object` and `Originating Identity Header` similar but not limited to those specified in the [OSB spec profiles page](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md).

## Credentials Object

This specification does not limit how the Credentials Object should look like as different authentication mechanisms can be used. Depending on the used authentication mechanism, additional fields holding the actual credentials MAY be included.

| Field | Type | Description |
| --- | --- | --- |
| basic | [basic credentials](#basic-credentials-object) | Credentials for basic authentication |
| token | string | Bearer token |

_Exactly_ one of the properties `basic` or `token` MUST be provided.

### Basic Credentials Object

| Field | Type | Description |
| --- | --- | --- |
| username* | string | username |
| password* | string | password |

\* Fields with an asterisk are REQUIRED.

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
