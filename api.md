
# Service Manager API

## Table of Contents

- [Overview](#overview)
- [Asynchronous Operations](#asynchronous-operations)
- [General Resource Management](#general-resource-management)
  - [Creating a Resource Entity](#creating-a-resource-entity)
  - [Fetching a Resource Entity](#fetching-a-resource-entity)
  - [Listing all Resource Entities of a Resource Type](#listing-all-resource-entities-of-a-resource-type)
  - [Patching a Resource Entity](#patching-a-resource-entity)
  - [Deleting a Resource Entity](#deleting-a-resource-entity)
- [Platform Management](#platform-management)
  - [Registering a Platform](#registering-a-platform)
  - [Fetchhing a Platform](#fetching-a-platform)
  - [Listing Platforms](#listing-platforms)
  - [Updating a Platform](#updating-a-platform)
  - [Deleting a Platform](#deleting-a-platform)
- [Service Broker Management](#service-broker-management)
  - [Registering a Service Broker](#registering-a-service-broker)
  - [Fetching a Service Broker](#fetching-a-service-broker)
  - [Listing Service Brokers](#listing-service-brokers)
  - [Updating a Service Broker](#updating-a-service-broker)
  - [Deleting a Service Broker](#deleting-a-service-broker)
- [Service Instance Management](#service-instance-management)
  - [Provisioning a Service Instance](#provisioning-a-service-instance)
  - [Fetching a Service Instance](#fetching-a-service-instance)
  - [Listing Service Instances](#listing-service-instances)
  - [Updating a Service Instance](#updating-a-service-instance)
  - [Deleting a Service Instance](#deleting-a-service-instance)
- [Service Binding Management](#service-binding-management)
  - [Creating a Service Binding](#creating-a-service-binding)
  - [Fetching a Service Binding](#fetching-a-service-binding)
  - [Listing Service Binding](#listing-service-bindings)
  - [Updating a Service Binding](#updating-a-service-binding)
  - [Deleting a Service Binding](#deleting-a-service-binding)
- [Service Offering Management](#service-offering-management)
  - [Fetching a Service Offering](#fetching-a-service-offering)
  - [Listing Service Offerings](#listing-service-offerings)
- [Service Plan Management](#service-plan-management)
  - [Fetching a Service Plan](#fetching-a-service-plan)
  - [Listing Service Plans](#listing-service-plans)
- [Information Management](#information-management)
- [OSB Management](#osb-management)
- [Credentials Object](#credentials-object)
- [State Object](#state-object)
- [Labels Object](#labels-object)
- [Errors](#errors)
- [Content Type](#content-type)
- [Mitigating Orphans](#mitigating-orphans)

## Overview

The Service Manager API defines an HTTP interface that allows the management of platforms, brokers, services, plans, service instances and service bindings from a central place. In general, the Service Manager API can be split into two groups - a Service Controller API that allows the Service Manager to act as an OSB platform for service brokers that are registered in SM (SM as a platform) and an OSB API which allows the Service Manager to act as a service broker for platforms that are registered in SM (SM as a broker). The latter implements the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/).

One of the access channels to the Service Manager is via the `smctl` CLI. The API should play nice in this context.
A CLI-friendly string is all lowercase, with no spaces. Keep it short -- imagine a user having to type it as an argument for a longer command.

## Asynchronous Operations

The Service Manager APIs for mutating (creating, deleting and updating) resources MUST work asynchronously. When such an operation is triggered, the Service Manager MUST respond with `202 Accepted` and a `Location header` specifying a location to obtain details about the `state` of this resource. Any Service Manager client MAY then use the Location header's value to poll for the `state` and use the details of the `state` to provide user facing information about the resource's state.

### Concurrent Mutating Requests

Service Manager does not support concurrent mutating operations on the same resource entity. If a resource with type `:resource_type` and id `:resource_id` is currently being created/updated/deleted and this operation is in progress, then no other asynchronous mutating operation can be executed on the resource of type `:resource_type` and id `:resource_id` until the one that is currently in progress finishes. If the Service Manager receives a concurrent mutating request that it currently cannot handle due to another operation being in progress for the same resource entity, the Service Manager MUST reject the request and return HTTP status `422 Unprocessable Entity` and a meaningful [errors object](#errors).

## General Resource Management

The following section generalizes how Service Manager resources are managed. A `resource_type` represents one set of resource entities (for example service brokers). A `resource_entity` represents one record of a resource type (for example one service broker record).

## Creating a Resource Entity

### Request

#### Route

`POST /v1/:resources_type`

`:resources_type` MUST be a valid Service Manager resource type.

#### Headers

The following HTTP Headers are defined for the operations:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |
| Location* | string | an URL from where information about the [state](#state-object) of the resource can be obtained |

\* Headers with an asterisk are REQUIRED.

#### Body

The body must be a valid JSON Object (`{}`).

For a success response, the response body MAY be `{}`.

Some APIs may allow passing in the resource entity `id` (that is the id to be used to uniquely identify the resource entity) for backward compatibility reasons. If an `id` is not passed as part of the request body, the Service Manager takes care of generating one. The `id` field MUST be returned as part of the response of a call to the Location URL.

### Response

| Status Code | Description |
| ----------- | ----------- |
| 202 Accepted | MUST be returned if a resouce creation is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with the same `name` already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

**Note:** In the case of a failed creation of a resource entity, the resource entity at the Location URL still exists for a certain period of time and returns proper `state` to reflect the creation failure.

## Fetching a Resource Entity

### Request

#### Route

`GET /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Headers

The following HTTP Headers are defined for the operations.

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |
| Location | string | an URL from where information about the [state](#state-object) of the resource can be obtained |

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`). Each resouce API in this document should include a relevant example.

The response body MAY include information about the resource's `state`.

In case of ongoing asynchronous update of the resource entity, this operation MUST return the old fields' values (the one known prior to the update as there is no guarantee if the update will be successful).

## Listing All Resource Entities of a Resource Type

Returns all resource entities of this resource type.

### Request

#### Route

`GET /v1/:resource_type`

`:resources_type` MUST be a valid Service Manager resource type.

This endpoint supports [paging](#paging).

This endpoint supports [filtering](#filtering).

### Headers

The following HTTP Headers are defined for the operations.

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |
| Location | string | an URL from where information about the [state](#state-object) of the resource can be obtained |

### Filtering Parameters

All `list` endpoints MUST support filtering.

There re two types of filtering.

1. Filtering based on labels.
2. Filtering based on resource fields (these are fields that are part of the resource's JSON representation).

Filtering can be controlled by the following query string parameters:

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| labelQuery | string | Filter the response based on the label query. Only items that have labels matching the provided label query will be returned. If present, MUST be a non-empty string. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |

    Example: `GET /v1/:resource_type?labelQuery=context_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all resource entities of the specified `resource_type` with a label `context_id` that has a value `bvsded31-c303-123a-aab9-8crar19e1218`.
    
    Example: `GET /v1/:resource_type?fieldQuery=field%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all resources of the specified type with value for `field` that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

### Paging Parameters

All `list` endpoints MUST support paging.

There are two types of paging.

1. Paging by skipping items. The `skip_count` parameter defines how many items should be skipped. The order of the items is server specific, but MUST NOT change between calls.
2. Paging by providing the ID of the last item of the previous page. The items MUST be ordered by their creation date. This paging method guarantees that no item is missed but it may be slower for big lists.

Paging can be controlled by the following query string parameters: 

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| max_items | int | the maximum number of items to return in the response. The server MUST NOT exceed this maximum but  MAY return a smaller number of items than the specified value. The server SHOULD NOT return an error if `max_items` exceeds the internally supported page size. It SHOULD return a smaller number of items instead. The default is implementation specific.
| skip_count | int | the number of potential results that the repository MUST skip/page over before returning any results. Defaults to 0. |
| last_id | string | the ID of the last item of the previous page. An empty string indicates that the first page is requested. |

### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK      | MUST be returned upon successful retrieval of the resource entities. The expected response body is below. |
| 400 Bad Request | MUST be returned if the values of the `max_items` parameter or the `skip_count` parameter is not a positive number or if both, the `skip_count` parameter and the `last_id` parameter are provided. MUST also be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`). Additional details are provided in the response body section of [paging](#paging).

The response MAY not contain information about the resource entities' `states`.

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| has_more_items* | boolean | `true` if the list contains additional items after those contained in the response.  `false` otherwise. If `true`, a request with a larger `skip_count` or larger `max_items` is expected to return additional results (unless the list has changed).
| num_items | int | if the server knows the total number of items in the result set, the server SHOULD include the number here. If the server does not know the number of items in the result set, this field MUST NOT be included. The value MAY NOT be accurate the next time the client retrieves the result set or the next page in the result set. |
| items* | array of objects | the list of items. This list MAY be empty. |

\* Fields with an asterisk are REQUIRED.

```json
{  
  "has_more_items": true,
  "num_items": 42,
  "items": [
      ...
  ]
}
```

## Patching a Resource Entity

### Request

#### Route

`PATCH /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Headers 

The following HTTP Headers are defined for the operations:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |
| Location* | string | an URL from where information about the [state](#state-object) of the resource can be obtained |

\* Headers with an asterisk are REQUIRED.

#### Body

The body MUST be a valid JSON Object (`{}`). Each resouce API in this document should include a relevant example.

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed. Fields that are explicitly supplied a `null` value MUST be nulled out provided that they are not mandatory for the resource type.

### Response

| Status Code | Description |
| ----------- | ----------- |
 202 Accepted | MUST be returned if a resouce creation is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or attempting to null out mandatory fields. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the response body MAY be `{}`.

**Note:** If the resource supports label, patching resource entities MUST also support patching the labels as specified in the [relevant section](#patching-labels).

## Deleting a Resource Entity

### Request

#### Route

`DELETE /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Headers 

The following HTTP Headers are defined for the operations:

| Header | Type | Description |
| ------ | ---- | ----------- |
| Authorization* | string | Provides a means for authentication and authorization |
| Location* | string | an URL from where information about the [state](#state-object) of the resource can be obtained |

\* Headers with an asterisk are REQUIRED.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| force | boolean | Whether to force the deletion of the resource and all asociated resources from Service Manager. No call to the actual Service Broker is performed. |

### Response

| Status Code | Description |
| ----------- | ----------- |
| 202 Accepted | MUST be returned if a resouce deletion is performed as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or there are service bindings associated with the service instance and `force` is not `true`. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |
| 404 Not Found | MUST be returned if the requested resource is missing. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

#### Body

The response body MUST be a valid JSON Object (`{}`).

For a success response, the expected response body MUST be `{}`.

**Note:** A response to a call to the Location URL will always return at least the `state` of the resource entity until the resource entity is gone (fully deleted) - then a `404 Not Found` MUST be returned.

## Platform Management

The resource supports [labels](#labels-object).

## Registering a Platform

In order for a platform to be usable with the Service Manager, the Service Manager needs to know about the platforms existence. Essentially, registering a platform means that a new service broker proxy for this particular platform has been registered with the Service Manager.

Creation of a `platform` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

### Route

`POST /v1/platforms`

### Request Body

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt",
    "labels": {
      "label1": ["value1"]
    }
}
```

| Request field | Type | Description |
| ------------- | ---- | ----------- |
| id  | string | ID of the platform. If provided, MUST be unique across all platforms registered with the Service Manager. |
| name* | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type* | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |
| labels | array of [labels](#label-object) | Additional data associated with the service broker. |

\* Fields with an asterisk are REQUIRED

## Fetching a Platform

Fetching of a `platform` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Route 

`GET /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

### Response Body

#### Platform Object

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
    },
    "labels": {
      "label1": ["value1"]
    },
    "state": {
      "ready": "True",
      "message": "Platform cf-eu-10 successfully provisioned"
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
| labels* | array of [labels](#label-object) | Additional data associated with the service broker. MAY be an empty array. |
| state | [state object](#state-object) | The state of the platform. |

\* Fields with an asterisk are REQUIRED.

## Listing Platforms

Listing `platforms` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

### Route

`GET /v1/platforms`

### Response Body

```json
{
  "has_more_items": false,
  "num_items": 2,
  "items": [
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
      },
      "labels": {
        "label1": ["value1"]
      }
    },
    {
      "id": "e031d646-62a5-4a50-9d8e-23165172e9e1",
      "name": "k8s-us-05",
      "type": "kubernetes",
      "description": "Kubernetes on GCP in us-west1",
      "created_at": "2016-06-08T17:41:22Z",
      "updated_at": "2016-06-08T17:41:26Z",
      "credentials" : {
        "basic": {
            "username": "admin2",
            "password": "secret2"
        }
      },
      "labels": {

      },
    }
  ]
}
```

## Updating a Platform

Updating of a `platform` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

### Route

`PATCH /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered platform.


#### Request Body

```json
{
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt",
    "labels": {

    }
}
```

| Request field | Type | Description |
| ------------- | ---- | ----------- |
| name | string | A CLI-friendly name of the platform. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed.

## Deleting a Platform

Deletion of a `platform` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

### Route

`DELETE /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

## Service Broker Management

The resource supports [labels](#labels-object).

## Registering a Service Broker

Registering a broker in the Service Manager makes the services exposed by this service broker available to all Platforms registered in the Service Manager.
Upon registration, Service Manager fetches and validate the catalog from the service broker.

Creation of a `service broker` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

### Route

`POST /v1/service_brokers`

### Request Body

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
    "labels": {
      "label1": ["value1"]
    }
  }
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| name* | string | A CLI-friendly name of the service broker. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all service brokers registered with the Service Manager. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url* | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials* | [credentials](#credentials-object) | MUST be a valid credentials object which will be used to authenticate against the service broker. |
| labels | array of [labels](#label-object) | Additional data associated with the service broker. |

\* Fields with an asterisk are REQUIRED.

## Fetching a Service Broker

Fetching of a `service broker` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Request

#### Route

`GET /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Response Body

#### Service Broker Object

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "created_at": "2016-06-08T16:41:26Z",
    "updated_at": "2016-06-08T16:41:26Z",
    "broker_url": "https://service-broker-url",
    "labels": {
      "label1": ["value1"]
    },
    "state": {
      "ready": "True",
      "message": "Service Broker service-broker-name successfully created"
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
| labels* | array of [labels](#label-object) | Additional data associated with the service broker. MAY be an empty array. |
| state | [state object](#state-object) | The state of the service broker. |

\* Fields with an asterisk are REQUIRED.

## Listing Service Brokers

Listing `service brokers` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).


### Route

`GET /v1/service_brokers`

### Response Body

```json
{
  "has_more_items": false,
  "num_item": 2,
  "items": [
    {
      "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
      "name": "service-broker-name",
      "description": "Service broker providing some valuable services",
      "created_at": "2016-06-08T16:41:26Z",
      "updated_at": "2016-06-08T16:41:26Z",
      "broker_url": "https://service-broker-url",
      "labels": {
        "label1": ["value1"]
      }
    },
    {
      "id": "a62b83e8-1604-427d-b079-200ae9247b60",
      "name": "another-broker",
      "description": "More services",
      "created_at": "2016-06-08T17:41:26Z",
      "updated_at": "2016-06-08T17:41:26Z",
      "broker_url": "https://another-broker-url",
      "labels": {

      }
    }
  ]
}
```

## Updating a Service Broker

Updating a service broker MUST trigger an update of the catalog of this service broker.

Updating of a `service broker` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

### Route

`PATCH /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

### Request Body

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
    "labels": {

    }
}
```

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | A CLI-friendly name of the service broker. MUST only contain alphanumeric characters and hyphens (no spaces). MUST be unique across all service brokers registered with the Service Manager. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials | [credentials](#credentials-object) | If provided, MUST be a valid credentials object which will be used to authenticate against the service broker. |
| labels | array of [labels](#label-object) | Additional data associated with the service broker. |

All fields are OPTIONAL. Fields that are not provided MUST NOT be changed.

## Deleting a Service Broker

Deletion of a service broker for which there are Service Instances created MUST fail. This behavior can be overridden by specifying the `force` query parameter which will remove the service broker regardless of whether there are Service Instances created by it.

Deletion of a `service broker` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

### Route

`DELETE /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

## Service Instance Management

The resource supports [labels](#labels-object).

## Provisioning a Service Instance

Creation of a `service instance` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

### Route

`POST /v1/service_instances`

### Request Body

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

**Note:** Service Manager MUST also handle [mitigating orphans](#orphans-mitigation) in the context of service instances.

## Fetching a Service Instance

Fetching of a `service instance` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Route

`GET /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

### Response Body

#### Service Instance Object

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
    "message": "Orphan mitigation required: Service Broker request timeout: PATCH https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114",
    "conditions": [  
      {  
        "type": "LastOperation",
        "status": "Failed",
        "message": "Service Broker request timeout: PATCH https://pg-broker.com/v2/service_instances/123-52c4b6f2-335a-44a3-c971-424ec78c7114",
        "name": "Update",
        "reason": "OperationTimeout"
      },
      {  
        "type": "OrphanMitigation",
        "status": "Required",
        "reason": "ServiceBrokerTimeout",
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

## Listing Service Instances

Listing `service instances` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).


### Route

`GET /v1/service_instances`

### Response Body

```json
{  
  "has_more_items": false,
  "num_items": 1,
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
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

## Updating a Service Instance

Updating of a `service instance` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

### Route

`PATCH /v1/service_instances/:service_instance_id`

`:service_instance_id` The ID of a previously provisioned service instance.

### Request Body

```json
{  
  "name": "new-instance-name",
  "parameters": [  
    { "op": "add", "key": "parameter1", "value": "value1" }
  ],
  "service_plan_id": "acsded31-c303-123a-aab9-8crar19e1218",
  "labels": [
    { "op": "add", "key": "label1", "values": ["test1", "test2"] },
    { "op": "add_value", "key": "label2", "values": ["test3"] },
    { "op": "replace", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label2" },
    { "op": "remove_value", "key": "label1", "values": ["test2"] }
  ]  
}
```

**Note:** Patching parameters works the same way as patching labels.

## Deleting a Service Instance

Deletion of a `service instance` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

## Route

`DELETE /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

## Service Binding Management

The resource supports [labels](#labels-object).

## Creating a Service Binding

Creation of a `service binding` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

### Route

`POST /v1/service_bindings`

### Request Body

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

**Note:** Service Manager MUST also handle [mitigating orphans](#orphans-mitigation) in the context of service bindings.

## Fetching a Service Binding

Fetching of a `service binding` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Route

`GET /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

### Response Body

#### Service Binding Object

```json
{  
  "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
  "name": "my-service-binding",
  "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
  "binding": {
    "credentials": {  
      "creds-key-63": "creds-val-63"
    }
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
    "message": "Service Binding is currently being deleted",
    "conditions": [  
      {  
        "type": "LastOperation",
        "status": "Success",
        "message": "Create deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353 succeeded at 2018-09-26T07:43:36.000Z",
        "name": "Create"
      }
    ]
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z"
}
```

## Listing Service Bindings

Listing `service bindings` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

### Route

`GET /v1/service_bindings`

###  Response Body

```json
{  
  "has_more_items": false,
  "num_items": 1,
  "items": [  
    {  
      "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
      "name": "my-service-binding",
      "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
      "binding": {
        "credentials": {  
          "creds-key-63": "creds-val-63"
        }
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
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z"
    }
  ]
}
```

## Updating a Service Binding

Updating of a `service binding` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

### Route

`PATCH /v1/service_bindings/:service_binding_id`

`:service_binding_id` The ID of a previously created service binding.

### Request Body

```json
{  
  "name": "new-binding-name",
  "labels": [
    { "op": "add", "key": "label1", "values": ["test1", "test2"] },
    { "op": "add_value", "key": "label2", "values": ["test3"] },
    { "op": "replace", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label2" },
    { "op": "remove_value", "key": "label1", "values": ["test2"] }
  ]  
}
```

## Deleting a Service Binding

Deletion of a `service binding` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

### Route

`DELETE /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

## Service Offering Management

The resource supports [labels](#labels-object).

## Fetching a Service Offering

Fetching of a `service offering` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Route

`GET /v1/service_offerings/:service_offering_id`

`:service_offering_id` MUST be the ID of a previously created service offering.

###  Response Body

#### Service Offering Object

```json
{  
  "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-offering",
  "description": "service offering description",
  "displayName": "postgres",
  "longDescription": "local postgres",
  "service_broker_id": "0e7250aa-364f-42c2-8fd2-808b0224376f",
  "bindable": true,
  "plan_updateable": false,
  "instances_retrievable": false,
  "bindings_retrievable": false,
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z",
  "labels": {

  }
}
```

## Listing Service Offerings

Listing `service offerings` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

### Route

`GET /v1/service_offerings`

### Response Body

```json
{  
  "has_more_items": true,
  "num_items": 523,
  "items":[  
    {  
      "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "my-service-offering",
      "description": "service offering description",
      "displayName": "display-name",
      "longDescription": "long-name",
      "service_broker_id": "0e7250aa-364f-42c2-8fd2-808b0224376f",
      "bindable": true,
      "plan_updateable": false,
      "instances_retrievable": false,
      "bindings_retrievable": false,
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z",
      "labels": {

      }
    }
  ]
}
```

## Service Plan Management

The resource supports [labels](#labels-object).

## Fetching a Service Plan

Fetching of a `service plan` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

### Route

`GET /v1/plans/:plan_id`

`:plan_id` MUST be the ID of a previously created plan.

### Response Body

#### Service Plan Object

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
  "updated_at": "2016-06-08T16:41:26Z",
  "labels": {

  }
}
```

\* Fields with an asterisk are REQUIRED.

## Listing Service Plans

Listing `service plans` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

### Route

`GET /v1/plans`

### Response Body

```json
{  
  "has_more_items": true,
  "num_items": 732,
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
      "updated_at": "2016-06-08T16:41:26Z",
      "labels": {

      }
    }
  ]
}
```

## Service Visibilities Management

There are currently ongoing dicussions as to how platform and service visilibities should be handled in SM.
TODO: Add content here.

## Information Management

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

## OSB Management

The OSB Management API is an implementation of the [OSB API specification](https://github.com/openservicebrokerapi/servicebroker). It enables the Service Manager to act as a central service broker and be registered as one in the  platforms that are associated with it (meaning the platforms that are registered in the Service Manager). The Service Manager also takes care of delegating the OSB calls to the registered brokers (meaning brokers that are registered in the Service Manager) that should process the request. As such, the Service Manager acts as a platform for the actual (registered) brokers.

### Request 

The OSB Management API prefixes the routes specified in the OSB spec with `/v1/osb/:broker_id`.

`:broker_id` is the id of the broker that the OSB call is targeting. The Service Manager MUST forward the call to this broker. The `broker_id` MUST be a globally unique non-empty string.

When a request is send to the OSB Management API, after forwarding the call to the actual broker but before returning the response, the Service Manager MAY alter the body of the response. For example, in the case of `/v1/osb/:broker_id/v2/catalog` request, the Service Manager MAY, amongst other things, add additional plans (reference plan) to the catalog.

In its role of a platform for the registered brokers, the Service Manager MAY define its own format for `Context Object` and `Originating Identity Header` similar but not limited to those specified in the [OSB spec profiles page](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md).

## Credentials Object

This specification does not limit how the Credentials Object should look like as different authentication mechanisms can be used. Depending on the used authentication mechanism, additional fields holding the actual credentials MAY be included.

**Note:** The following structure of the credentials object does not apply for Service Binding credentials. Service Binding credentials are provided by the Service Broker and MAY be free form as long as they comply with the OSB specification.

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

All resources that support mutation operations (creation, deletion and update) MUST contain a `state` object. After performing a mutation request, the response MUST include a `Location` header from where information about the resource's `state` can be obtained. This MAY or MAY NOT be the `Retrieve` (`GET`) API for the resource entity that is being mutated.

The `state` reflects the real state in which the resource currently is. It includes information regarding whether the resource is currently usable or not (`ready` or not) and it contains `conditions` that provide further details if the resource is not ready (is not usable).

The `state` is of particular interest when the mutation operations are asynchronous. But even synchronously mutatable resources should provide `state` for consistency reasons. This `state` of synchronously mutated resources would often include no conditions.

| Field | Type | Description |
| ----- | ---- | ----------- |
| ready* | boolean | Indicates whether a resource is ready for use or not. This value is calculated by the Service Manager based on the conditions' statuses using a resource specific aggregation policy for the conditions that are defined for this resource |
| conditions* | array of [conditions](#conditions-object) | Describe the state of the resource and indicate what actions should be taken in order for the resource to become ready. May be an empty array |
| message* | string | Human-readable summary for the reasoning behind the `ready` being what it is |

### Conditions Object

The `conditions` describe the current condition in which the resource is. 
Each resource MAY add resource specific conditions and should also handle those conditions accordingly in case they sum up to an undesired `state` (in most cases this would be a `ready:false` state).
Each `condition` MAY include additional fields apart from those specified below in order to provide meaningful information.

| Field | Type | Description |
| ----- | ---- | ----------- |
| type* | string | The type of the condition. Each resource defines a set of condition types that are relevant for it. |
| status* | string | The status of the condition. Each condition defines its own status values and gives them semantics. Used to determine whether any actions should be taken in regards of this condition. For example, a condition of type `last_operation` with status `in_progress` would imply that the operation is still in running. If the status is `success` it would imply that the operation has successfully finished and if it is `failed` it would imply that the `last_operation` failed |
| message | string | Human-readable details that describe the condition |

The `state` MUST be maintained up-to-date and reflect the real state of the resource. When a process or a component takes actions due to the `state` not matching what is actually desired, the process or component MUST also take care of updating the respective  `conditions` that it has performed actions upon. When any conditions are updated the `ready` field MUST be recalculated and updated by the Service Manager.

Each Service Manager resource MUST define the conditions that are relevant for it. It MUST also define an aggregation policy that sums up the `conditions` and decides whether the resource is `ready` or not. Based on this policy every time a resource's `condition` is changed, the `ready` field should be recalculated and updated. The fact that each resource defines it's own `conditions` and an aggregation policy based on those `conditions` is an implementation detail but it is worth mentioning it here to better describe the idea behind the `state`.

Example Resource Entity with a State Object:

```json
{
  "id": "0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
  ...
  "state": {  
    "ready": "False",
    "message": "Service Binding is currently being created",
    "conditions": [  
      {  
        "type": "last_operation",
        "status": "in_progress",
        "message": "Creating deployment pg-0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
        "name": "Create"
      }
    ]
  }
}  
```

The example state above represents the state of a resource called `service_binding` with an `id` equal to `0941-12c4b6f2-335a-44a3-b971-424ec78c7353`. The `state` implies that the service binding is not ready (it is not usable) due to the fact that the last operation (namely Create, hence the `name` field) performed on this entity is currently still running (the `status` of the `last_operation` `condition` is `in_progress`).

## Labels Object

A label is a key-value pair that can be attached to a resource. Service Manager resources MAY have any number of labels represented by the `labels` field.

This allows querying (filtering) on the `List` API of the resource based on multiple labels. The Service Manager MAY
attach additional labels to the resources and MAY restrict updates and deletes for some of the labels.

The `labels` MUST be returned as part of the `List` and `Fetch` APIs.

Example of a Resource Entity that has labels:

```json
{
  "id": "0941-12c4b6f2-335a-44a3-b971-424ec78c7353",
  ...
  "labels": {  
      "label1Key": [
        "label1Value"
      ],
      "label2Key": [
        "label2Value1"
      ]
    }
}  
```

### Naming Labels

TODO: Add rules for labels naming

### Patching Labels

The PATCH APIs of the resources that support labels MUST support the following `label operations` in order to update labels and label values.

| Operation | Description |
| --------- | ----------- |
| add | Adds a new label with the name in `label`. The `value` MUST be a string or an array of strings. If the label already exists, the operation fails. |
| add_values | Appends a new value to a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails. |
| replace | Replaces a all values of a label with new values. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails. |
| remove | Removes a label. If the label does not exist, the operation fails. |
| remove_values | Removes a value from a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails |

If one operations fails, none of the changes will be applied.

#### Example

##### Route

`PATCH /v1/:resources_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Request Body

```json
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

#### Response Body

```json
...
"labels": [
  {
    "oldLabel": [
      "oldLabelValue1", "oldLabelValue2"
    ]
  },
  {
    "label1": [
      "test1"
    ]
  }
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

## Mitigating Orphans

Service Manager MUST also handle properly the orphan mitigation process as described in the [orphan's section](https://github.com/openservicebrokerapi/servicebroker/blob/master/spec.md#orphans) of the OSB spec. How this is done is an implementation detail. One possible way would be for the `state` of service instances to include an `OrphanMitigation` `condition` that contains a details whether orphan mitigation is required or not. When orphan mitigation is required, the relevant process that takes actions based on the `state` MUST take the necessary steps (keep trying to delete the resource entity) to ensure orphans are mitigated correctly.