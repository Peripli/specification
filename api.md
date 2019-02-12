
# Service Manager API

## Table of Contents

- [Overview](#overview)
- [Asynchronous Operations](#asynchronous-operations)
- [General Resource Management](#general-resource-management)
  - [Creating a Resource Entity](#creating-a-resource-entity)
  - [Fetching a Resource Entity](#fetching-a-resource-entity)
  - [Listing all Resource Entities of a Resource Type](#listing-all-resource-entities-of-a-resource-type)
  - [Updating a Resource Entity](#updating-a-resource-entity)
  - [Deleting a Resource Entity](#deleting-a-resource-entity)
  - [Getting an Operation Status](#getting-an-operation-status)
  - [Getting Entity Operations](#getting-entity-operations)
- [Resource types](#resource-types)
- [Platform Management](#platform-management)
  - [Registering a Platform](#registering-a-platform)
  - [Fetching a Platform](#fetching-a-platform)
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
- [Service Visibility Management](#service-visibility-management)
- [Information Management](#information-management)
- [OSB Management](#osb-management)
- [Credentials Object](#credentials-object)
- [Status Object](#status-object)
- [Labels Object](#labels-object)       
- [Errors](#errors)
- [Content Type](#content-type)
- [Mitigating Orphans](#mitigating-orphans)

## Overview

The Service Manager API defines an REST interface that allows the management of platforms, brokers, service offerings, plans, service instances and service bindings from a central place. The Service Manager API can be split into three groups - a Service Manager Admin API to manage brokers and attached platforms, a Service Controller API that allows the Service Manager to act as an OSB platform for service brokers that are registered in Service Manager (Service Manager as a platform) and an OSB API which allows the Service Manager to act as a service broker for platforms that are registered in Service Manager (Service Manager as a broker). The latter implements the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/).

One of the access channels to the Service Manager is via the `smctl` CLI. The API should play nice in this context.


## Terminology and Definitions

This document inherits the terminology from the Service Manager specification and [Open Service Broker API](https://github.com/openservicebrokerapi/servicebroker/) specification.

Additionally, the follow terms and concepts are use:

* *ID*: An ID is globally unique identifier. An ID MUST NOT be longer than 100 characters and SHOULD only consist of alphanumeric characters, periods, and hyphens. Using a GUID is RECOMMENDED.
* *CLI-friendly name*: A CLI-friendly name is a short string that SHOULD only use lowercase alphanumeric characters, periods, hyphens, and no white spaces. A name MUST NOT exceed 255 character, but it is RECOMMENDED to keep it much shorter -- imagine a user having to type it as an argument for a longer command.
* *Description*: A description is a human readable string, which SHOULD NOT exceed 255 characters. If a description is longer than 255 characters, the Service Manager MAY silently truncate it.


## Authentication an Authorization

Unless there is some out of band communication and agreement between a Service Manager client and the Service Manager, a client MUST authenticate with the Service Manager using OAuth 2.0 (the `Authorization:` header) on every request. 

The Service Manager MUST return a `401 Unauthorized` response if the authentication fails.

The Service Manager MUST return a `403 Forbidden` response if the client is not authorized to perform the requested operation.

In both cases, the response body SHOULD follow the [Errors](#errors) section.

This specification does not define any permission model. Authorization checks are Service Manager implementation specific. However, the Service Manager SHOULD follow these basic guidelines:

*  If a user is allowed to update or delete an entity, the user SHOULD also be allowed to fetch and list the entity and to see the status of the entity.
* If a user is allowed to see an entity, the user SHOULD have access to *all* fields and labels of the entity.
* The Service Manager MAY restrict write access to some fields and labels. There is no way for the client to find out in advance which data can be updated.

## Asynchronous Operations

The Service Manager APIs for creating, updating, and deleting entities MAY work asynchronously. When such an operation is triggered, the Service Manager MAY respond with `202 Accepted` and a `Location header` specifying a URL to obtain the [operation status](#status-object). A Service Manager client MAY then use the Location header's value to [poll for the status](#getting-an-operation-status). Once the operation has finished, the client SHOULD stop polling. The Service Manager keeps and provides [operation status](#status-object) for certain period of time after the operation has finished.
The Service Manager MAY decide to execute operations synchronously. In this case it responses with `200 Ok`, `201 Created`, or `204 No Content`, depending on the operation.

### Concurrent Mutating Requests

Service Manager MAY NOT support concurrent mutating operations on the same resource entity. If a resource with type `:resource_type` and ID `:resource_id` is currently being created, updated or deleted and this operation is in progress, then other mutating operation MAY fail on the resource of type `:resource_type` and ID `:resource_id` until the one that is currently in progress finishes. If the Service Manager receives a concurrent mutating request that it currently cannot handle due to another operation being in progress for the same resource entity, the Service Manager MUST reject the request and return HTTP status `422 Unprocessable Entity` and a meaningful [errors object](#errors).
The client MAY retry the request after the operation has finished.

## General Resource Management

The following section generalizes how Service Manager resources are managed. A `resource_type` represents one set of resource entities (for example service brokers). A `resource_entity` represents one record of a resource type (for example one service broker record).

### Creating a Resource Entity

#### Request

##### Route

`POST /v1/:resources_type`

`:resources_type` MUST be a valid Service Manager resource type.

##### Body

The body MUST be a valid JSON Object.

Some APIs may allow passing in the resource entity `id` (that is the ID to be used to uniquely identify the resource entity) for backward compatibility reasons. If an `id` is not passed as part of the request body, the Service Manager takes care of generating one.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if the resource has been created. |
| 202 Accepted | MUST be returned if a resource creation is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with the same `name` or `id` already exists. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |
| 422 Unprocessable Entity | MUST be returned if another operation for a resource with the same `name` or `id` is already in progress. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Location | string | An URL from where the [status](#status-object) of the operation can be obtained. This header MUST be present if the status `202 Accepted` has been returned and MUST NOT be present for all other status codes. |

##### Body

Unless defined otherwise in the sections below, the response body MUST be [the representation of the entity](#fetching-a-resource-entity) if the status code is `201 Created` or MUST be a [status object](#status-object) if the status code is `202 Accepted`.



### Fetching a Resource Entity

#### Request

##### Route

`GET /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing, if a creation operation is still in progress, or if the user is not allowed to know this resource. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Body

The response body MUST be a valid JSON Object. Each resource API in this document should include a relevant example.

In case of ongoing asynchronous update of the resource entity, this operation MUST return the old fields' values (the one known prior to the update as there is no guarantee if the update will be successful).

### Listing All Resource Entities of a Resource Type

Returns all resource entities of this resource type.

#### Request

##### Route

`GET /v1/:resource_type`

`:resources_type` MUST be a valid Service Manager resource type.

This endpoint MUST support [filtering](#filtering-Parameters) and [paging](#paging-parameters).

#### Filtering Parameters

There are two types of filtering.

1. Filtering based on labels.
2. Filtering based on resource fields (these are fields that are part of the resource's JSON representation).

Filtering can be controlled by the following query string parameters:

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| labelQuery | string | Filter the response based on the label query. Only items that have labels matching the provided label query will be returned. If present, MUST be a non-empty string. |
| fieldQuery | string | Filter the response based on the field query. Only items that have fields matching the provided label query will be returned. If present, MUST be a non-empty string. |


  Example: `GET /v1/:service_instances?labelQuery=context_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service instances with a label `context_id` that has a value `bvsded31-c303-123a-aab9-8crar19e1218`.

  Example: `GET /v1/:service_instances?fieldQuery=service_plan_id%3Dbvsded31-c303-123a-aab9-8crar19e1218` would return all service instances with a service plan ID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.


##### Filter Syntax and Rules

A filter sting MUST follow this format:
`<field|label>=<value>[;<field|label>=<value>[...]]`

* `<field|label>` is the name of the field or the label and MUST NOT be an empty string.
* The only supported operator is equals ('`=`'). There MUST be no white spaces before the '`=`' character. White spaces after the '`=`' character are interpreted as part of the value. The value MAY be an empty string.
* `<value>` is the value of the field or label. Semicolon ('`;`') and back slash ('`\`') characters MUST be escaped with a backslash ('`\`'). That is, the client has to change '`;`' to '`\;`' and '`\`' to '`\\`'.
* Multiple field or label queries are separated by a semicolon ('`;`'). The returned list MUST only contain entries that match all conditions.  
Example: `platform_id=3f04164d-6aef-4438-9bf2-08f9dd5d2edb;service_id=31129f3c-2e19-4abb-b509-ceb1cd157132`

* The Service Manager SHOULD support field queries on top-level fields with string, boolean, and integer values. The interpretation of other value types is implementation specific. In general, the Service Manager SHOULD reject field queries for all other value types.
* The Service Manage SHOULD support queries on all fields that hold a name or an ID. These fields are usually named '`id`' or '`name`' or the field name ends with '`_id`'.
* The Service Manager MAY also support field queries on nested fields. If so, the path to the field MUST be separated by a dot ('`.`'). Elements of an array are addressed with the index after the field name in square brackets('`[]`'). For example, a path could look like this: `credentials[0].basic.username`.

* The Service Manager SHOULD support label queries for labels that are visible to the current user.
* A label query condition is met if the query value matches at least one value in the labels value array.

* Label and field queries MAY be combined. The returned list MUST only contain entries that match both queries.

#### Paging Parameters

All `list` endpoints MUST support paging.

There are two types of paging.

1. Paging by skipping items. The `skip_count` parameter defines how many items should be skipped. The order of the items is server specific, but MUST NOT change between calls.
2. Paging by providing the ID of the last item of the previous page. The items MUST be ordered by their creation date. This paging method guarantees that no item is missed but it may be slower for larger lists.

Paging can be controlled by the following query string parameters: 

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| max_items | int | the maximum number of items to return in the response. The server MUST NOT exceed this maximum but MAY return a smaller number of items than the specified value. The server SHOULD NOT return an error if `max_items` exceeds the internally supported page size. It SHOULD return a smaller number of items instead. The default is implementation specific. |
| skip_count | int | the number of potential results that the repository MUST skip/page over before returning any results. Defaults to 0. |
| last_id | string | the ID of the last item of the previous page. An empty string indicates that the first page is requested. The existence of this query string field indicates that the client chooses the second paging type. |

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK      | MUST be returned upon successful retrieval of the resource entities. The expected response body is below. |
| 400 Bad Request | MUST be returned if the values of the `max_items` parameter or the `skip_count` parameter is not a positive number or if both, the `skip_count` parameter and the `last_id` parameter are provided. MUST also be returned if the request is malformed or missing mandatory data. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Body

The response body MUST be a valid JSON Object.

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| has_more_items* | boolean | `true` if the list contains additional items after those contained in the response.  `false` otherwise. If `true`, a request with a larger `skip_count` or larger `max_items` is expected to return additional results (unless the list has changed or `max_items` exceeds the internally supported page size).
| num_items | int | if the server knows the total number of items in the result set, the server SHOULD include the number here. If the server does not know the number of items in the result set, this field MUST NOT be included. The value MAY NOT be accurate the next time the client retrieves the result set or the next page in the result set. |
| items* | array of objects | the list of items. This list MAY be empty. |

\* Fields with an asterisk are REQUIRED.

```json
{  
  "has_more_items": true,
  "num_items": 42,
  "items": [
    {
      "id": "a62b83e8-1604-427d-b079-200ae9247b60",
      ...
    },
    ...
  ]
}
```

### Updating a Resource Entity

#### Request

##### Route

`PATCH /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Body

The body MUST be a valid JSON Object. Each resource API in this document should include a relevant example.

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed. Fields that are explicitly supplied a `null` value MUST be nulled out provided that they are not mandatory for the resource type.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the resource has been updated. |
| 202 Accepted | MUST be returned if a resource updating is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or attempting to null out mandatory fields. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors).|
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |
| 422 Unprocessable Entity | MUST be returned if another operation in already in progress. |

Responses with any other status code will be interpreted as a failure. The response MAY include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Location | string | An URL from where the [status](#status-object) of the operation can be obtained. This header MUST be present if the status `202 Accepted` has been returned and MUST NOT be present for all other status codes. |

##### Body

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | Representation of the updated entity. The returned JSON object MUST be the same that is returned by the corresponding [fetch endpoint](#fetching-a-resource-entity). |
| 202 Accepted | The initial [Status Object](#status-object). |
| 4xx | An [Error Object](#errors). |

**Note:** If the resource supports label, patching resource entities MUST also support patching the labels as specified in the [relevant section](#patching-labels).

### Deleting a Resource Entity

#### Request

##### Route

`DELETE /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Parameters

| Query-String Field | Type | Description |
| ---- | ---- | ----------- |
| force | boolean | Whether to force the deletion of the resource and all associated resources from Service Manager. Using this flag may result in inconsistent data! Defaults to `false`. |
| cascade | boolean | Some resources cannot be deleted if there are certain other resources that semantically link to them (for example a service instance can only be deleted if all the service bindings to it are deleted first). This parameter allows cascade deletion of resource entities that are associated with a particular resource entity before deleting the actual resource entity. *A cascading delete is not an atomic operation!* If the deletion of a linked entity fails, this operations fails, but other linked entities might have already been deleted. Defaults to `false`. |

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the resource has been deleted. The body MUST a non-empty, valid JSON object. If no data should be be returned from the Service Manager, the status code `204 No Content` SHOULD be used. |
| 202 Accepted | MUST be returned if a resource deletion is successfully initiated as a result of this request. |
| 204 No Content | MUST be returned if the resource has been deleted and there is no additional data provided by the Service Manager. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or there are resource entities associated with the resource entity that is being deleted and `cascade` and `force` are `false`. The `description` field MAY be used to return a user-facing error message, as described in [Errors](#errors). |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors). |
| 422 Unprocessable Entity | MUST be returned if another operation in already in progress. |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Location | string | An URL from where the [status](#status-object) of the operation can be obtained. This header MUST be present if the status `202 Accepted` has been returned and MUST NOT be present for all other status codes. |

##### Body

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | A valid JSON object. |
| 202 Accepted | The initial [Status Object](#status-object). |
| 204 No Content | No body MUST be provided. |
| 4xx | An [Error Object](#errors). |


### Getting an Operation Status

#### Request

##### Route

`GET /v1/status/:operation_id`

`:operation_id` is an opaque operation identifier.

#### Parameters

None.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the status is available. |
| 410 Gone | MUST be returned if the requested status doesn't exist or if the user is not allowed to know this status. The client SHOULD cease polling. |

Responses with any other status code will be interpreted as a failure. The client SHOULD continue polling until the Service Manager returns a valid response or the maximum polling duration is reached.

##### Response Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Retry-After | integer | The number of seconds to wait before checking the status again. This header SHOULD only be provided if the operation is still in progress. |

##### Response Body

If the status code is 200, the response body MUST be a [Status Object](#status-object).


### Getting Entity Operations


#### Request

##### Route

`GET /v1/:resource_type/:resource_entity_id/status`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. The `description` field MAY be used to return a user-facing error message, providing details about which part of the request is malformed or what data is missing as described in [Errors](#errors). |

Responses with any other status code will be interpreted as a failure. The response can include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Body

```json
{
  "status": [
    {
      "operation_id": "42fcdf1f-79bc-43e1-8865-844e82d0979d",
      "state": "in progress",
      "description": "working on it",
      "start_time": "2016-07-09T17:50:00Z",
      "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457"
    },
    {
      "operation_id": "c7880869-e1e8-403a-b57c-1396f5c89239",
      "state": "failed",
      "description": "deletion failed",
      "start_time": "2016-07-09T17:48:01Z",
      "end_time": "2016-07-09T17:48:22Z",
      "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457",
      "error" : {
        "error": "PermissionDenied",
        "description": "User has no permission to delete the platform entry."
      }
    }
  ]
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| status* | array of [Status Objects](#status-object) | A list of all status objects related to this entity. All "in progress" operations MUST be present, all other status known to the Service Manager SHOULD be present. This list MAY be empty if no operation is in process. |

\* Fields with an asterisk are REQUIRED.


## Resource Types

Service Manager currently defines the following resource types the APIs for which MUST comply with the [general resource management section](#general-resource-management).

### Platforms

The `platforms` API is described [here](#platform-management).

Definition of the semantics behind the resource can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Brokers

The `service brokers` API is described [here](#service-broker-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Instances

The `service instances` API is described [here](#service-instance-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Bindings

The `service bindings` API is described [here](#service-binding-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Offerings

The `service offerings` API is described [here](#service-offering-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Plans

The `service plans` API is described [here](#service-plan-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Visibilities

The `service visibilities` resource represents enforced visibility policies for service offerings and plans. This allows the Service Manager to specify where service plans are visible (in which platforms, CF orgs, etc).

The `service visibilities` API is described [here](#service-visibility-management).

## Platform Management

### Registering a Platform

In order for a platform to be usable with the Service Manager, the Service Manager needs to know about the platforms existence. Essentially, registering a platform would allow the Service Manager to manage the service brokers and service visibilities in this platform.

Creation of a `platform` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/platforms`

#### Request Body

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
| id  | string | ID of the platform. If provided, MUST be unique across all platforms registered with the Service Manager. If not provided, the Service Manager generates an ID. |
| name* | string | A CLI-friendly name of the platform. MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type* | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |

\* Fields with an asterisk are REQUIRED

### Fetching a Platform

Fetching of a `platform` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route 

`GET /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

#### Response Body

##### Platform Object

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
    }
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the platform. |
| name* | string | Platform name. |
| type* | string | Type of the platform. |
| description | string | Platform description. |
| credentials* | [credentials](#credentials-object) | A JSON object that contains credentials which the service broker proxy (or the platform) MUST use to authenticate against the Service Manager. Service Manager SHOULD be able to identify the calling platform from these credentials. |
| created_at | string | The time of the creation in ISO-8601 format. |
| updated_at | string | The time of the last update in ISO-8601 format. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |

\* Fields with an asterisk are REQUIRED.

### Listing Platforms

Listing `platforms` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/platforms`

#### Response Body

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
      }
    }
  ]
}
```

### Updating a Platform

Updating of a `platform` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PATCH /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered platform.


##### Request Body

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
| name | string | A CLI-friendly name of the platform. MUST be unique across all platforms registered with the Service Manager. MUST be a non-empty string. |
| type | string | The type of the platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| description | string | A description of the platform. |
| labels | collection of label patches | See [Patching Labels](#patching-labels). |

All fields are OPTIONAL. Fields that are not provided, MUST NOT be changed.

### Deleting a Platform

Deletion of a `platform` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

#### Route

`DELETE /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered platform.

## Service Broker Management

### Registering a Service Broker

Registering a broker in the Service Manager makes the services exposed by this service broker available to all Platforms registered in the Service Manager.
Upon registration, Service Manager fetches and validate the catalog from the service broker.

Creation of a `service broker` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/service_brokers`

#### Request Body

```json
{
    "name": "service-broker-name",
    "description": "Service broker providing some valuable services",
    "broker_url": "http://service-broker.example.com",
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
| name* | string | A CLI-friendly name of the service broker. The Service Manager MAY change this name to make it unique across all registered brokers. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url* | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials* | [credentials](#credentials-object) | MUST be a valid credentials object which will be used to authenticate against the service broker. |
| labels | collections of [labels](#labels-object) | Additional data associated with the service broker. |

\* Fields with an asterisk are REQUIRED.

### Fetching a Service Broker

Fetching of a `service broker` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Request

##### Route

`GET /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

##### Response Body

##### Service Broker Object

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
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id*            | string | ID of the service broker. |
| name*          | string | Name of the service broker. |
| description    | string | Description of the service broker. |
| broker_url*    | string | URL of the service broker. |
| created_at     | string | The time of creation in ISO-8601 format. |
| updated_at     | string | The time of the last update in ISO-8601 format. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the service broker. MAY be an empty object. |

\* Fields with an asterisk are REQUIRED.

### Listing Service Brokers

Listing `service brokers` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/service_brokers`

#### Response Body

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

### Updating a Service Broker

Updating a service broker MUST trigger an update of the catalog of this service broker.

Updating of a `service broker` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PATCH /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Request Body

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
| name | string | A CLI-friendly name of the service broker. The Service Manager MAY change this name to make it unique across all registered brokers. MUST be a non-empty string. |
| description | string | A description of the service broker. |
| broker_url | string | MUST be a valid base URL for an application that implements the OSB API |
| credentials | [credentials](#credentials-object) | If provided, MUST be a valid credentials object which will be used to authenticate against the service broker. |
| labels | array of label patches | See [Patching Labels](#patching-labels). |

All fields are OPTIONAL. Fields that are not provided MUST NOT be changed.

### Deleting a Service Broker

Deletion of a service broker for which there are Service Instances created MUST fail. This behavior can be overridden by specifying the `force` query parameter which will remove the service broker regardless of whether there are Service Instances created by it.

Deletion of a `service broker` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

#### Route

`DELETE /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

## Service Instance Management

### Provisioning a Service Instance

Creation of a `service instance` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/service_instances`

#### Request Body

##### Service Instance Object

```json
{  
  "name": "my-service-instance",
  "service_id": "service-offering-id-here",
  "plan_id": "service-plan-id-here",
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

| Request field | Type | Description |
| -------------- | ---- | ----------- |
| name* | string | A non-empty instance name. |
| service_id* | string | MUST be the ID of a Service Offering. |
| plan_id* | string | MUST be the ID of a Service Plan. |
| parameters | object | object	Configuration parameters for the Service Instance. |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty array. |

\* Fields with an asterisk are REQUIRED.

**Note:** Service Manager MUST also handle [mitigating orphans](#orphans-mitigation) in the context of service instances.

### Fetching a Service Instance

Fetching of a `service instance` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

#### Response Body

##### Service Instance Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-instance",
  "service_id": "31129f3c-2e19-4abb-b509-ceb1cd157132",
  "plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "platform_id": "3f04164d-6aef-4438-9bf2-08f9dd5d2edb", 
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
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Service Instance ID. | 
| name* | string | Service Instance name. |
| service_id* | string | MUST be the ID of a Service Offering. |
| plan_id* | string | MUST be the ID of a Service Plan. |
| platform_id* | string | MUST be the ID of the platform that owns this instance. |
| dashboard_url | string | The URL of a web-based management user interface for the Service Instance; we refer to this as a service dashboard.  |
| parameters | object |	Configuration parameters for the Service Instance. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty array. |
| created_at | string | The time of the creation in ISO-8601 format. |
| updated_at | string | The time of the last update in ISO-8601 format. |
| orphan | boolean | If `true` the Service Instance is an orphan and will eventually be removed by the Service Manager. If `false` the Service Instance is useable. This field MUST only be present, if the Service Instance has been created by the Service Manager. |

\* Fields with an asterisk are REQUIRED.

### Listing Service Instances

Listing `service instances` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/service_instances`

### Response Body

##### Array of Service Instance Objects

:warning: TODO

```json
{  
  "has_more_items": false,
  "num_items": 1,
  "items": [  
    {  
      "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "my-service-instance",
      "service_id": "31129f3c-2e19-4abb-b509-ceb1cd157132",
      "plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
      "platform_id": "3f04164d-6aef-4438-9bf2-08f9dd5d2edb", 
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

### Updating a Service Instance

Updating of a `service instance` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PATCH /v1/service_instances/:service_instance_id`

`:service_instance_id` The ID of a previously provisioned service instance.

#### Request Body

```json
{  
  "name": "new-instance-name",
  "parameters": [  
    { "op": "add", "key": "parameter1", "value": "value1" }
  ],
  "plan_id": "acsded31-c303-123a-aab9-8crar19e1218",
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

### Deleting a Service Instance

Deletion of a `service instance` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

Deletion of a service instance that has service bindings MUST fail unless `cascade` or `force` query parameter is `true`.

#### Route

`DELETE /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

## Service Binding Management

### Creating a Service Binding

Creation of a `service binding` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/service_bindings`

#### Request Body

##### Service Binding Object

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

| Request field | Type | Description |
| -------------- | ---- | ----------- |
| name* | string | A non-empty instance name. |
| service_instance_id* | string | MUST be the ID of a Service Instance. |
| bind_resource | BindResource | See `bind_resource` in the OSB API specification. |
| parameters | object | Configuration parameters for the Service Binding. Service Brokers SHOULD ensure that the client has provided valid configuration parameters and values for the operation. |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty array. |

\* Fields with an asterisk are REQUIRED.

**Note:** Service Manager MUST also handle [mitigating orphans](#orphans-mitigation) in the context of service bindings.

### Fetching a Service Binding

Fetching of a `service binding` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

#### Response Body

##### Service Binding Object

```json
{  
  "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
  "name": "my-service-binding",
  "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
  "platform_id": "3f04164d-6aef-4438-9bf2-08f9dd5d2edb", 
  "binding": {
    "credentials": {  
      "creds-key-63": "creds-val-63",
      "url": "https://my.example.org"
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
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Service Binding ID. | 
| name* | string | Service Binding name. |
| service_instance_id* | string | Service Instance ID. |
| platform_id* | string | MUST be the ID of the platform that owns this instance. |
| binding* | object | The binding returned by the Service Broker. In most cases, this object contains a `credentials` object. |
| parameters | object | Configuration parameters for the Service Binding. Service Brokers SHOULD ensure that the client has provided valid configuration parameters and values for the operation. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation in ISO-8601 format. |
| updated_at | string | The time of the last update in ISO-8601 format. |
| orphan | boolean | If `true` the Service Binding is an orphan and will eventually be removed by the Service Manager. If `false` the Service Binding is useable. This field MUST only be present, if the Service Binding has been created by the Service Manager. |

\* Fields with an asterisk are REQUIRED.

### Listing Service Bindings

Listing `service bindings` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/service_bindings`

####  Response Body

:warning: TODO 

```json
{  
  "has_more_items": false,
  "num_items": 1,
  "items": [  
    {  
      "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
      "name": "my-service-binding",
      "service_instance_id": "asd124bc21-df28-4891-8d91-46334e04600d",
      "platform_id": "3f04164d-6aef-4438-9bf2-08f9dd5d2edb", 
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

Updating of a `service binding` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PATCH /v1/service_bindings/:service_binding_id`

`:service_binding_id` The ID of a previously created service binding.

#### Request Body

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

| Request field | Type | Description |
| -------------- | ---- | ----------- |
| name | string | A non-empty instance name. |
| labels | array of label patches | See [Patching Labels](#patching-labels). |

\* Fields with an asterisk are REQUIRED.

### Deleting a Service Binding

Deletion of a `service binding` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

#### Route

`DELETE /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

## Service Offering Management

As per the OSB API terminology a service offering represents the advertisement of a service that a service broker supports. Service Manager MUST expose a management API of the service offerings offered by the registered service brokers.

### Fetching a Service Offering

Fetching of a `service offering` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_offerings/:service_offering_id`

`:service_offering_id` MUST be the ID of a previously created service offering.

####  Response Body

##### Service Offering Object

```json
{  
  "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-offering",
  "broker_id": "7905b30e-cd9e-4d8a-adc8-1f644e49dae5",
  "service": {
    "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
    "name": "my-service-offering",
    "description": "service offering description",
    "displayName": "postgres",
    "longDescription": "local postgres",
    "bindable": true,
    "plan_updateable": false,
    "instances_retrievable": false,
    "bindings_retrievable": false,
    ...
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z",
  "labels": {
  }
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Service Offering ID. | 
| name* | string | Service Offering name. |
| broker_id* | string | The ID of the broker that provides this Service Offering. | 
| service* | object | The Service Offering object as provided by the broker, but without the `plans` field. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation in ISO-8601 format. |
| updated_at | string | The time of the last update in ISO-8601 format. |

\* Fields with an asterisk are REQUIRED.

### Listing Service Offerings

Listing `service offerings` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/service_offerings`

#### Response Body

```json
{  
  "has_more_items": true,
  "num_items": 523,
  "items":[
    {  
      "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "my-service-offering",
      "broker_id": "7905b30e-cd9e-4d8a-adc8-1f644e49dae5",
      "service": {
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
        ...
      }
      "created_at": "2016-06-08T16:41:22Z",
      "updated_at": "2016-06-08T16:41:26Z",
      "labels": {
      }
    },
    ...
  ]
}
```


## Service Plan Management

As per the OSB API terminology, a service plan is representation of the costs and benefits for a given variant of the service, potentially as a tier that a service broker offers. Service Manager MUST expose a management API of the service plans offered by services of the registered service brokers.

### Fetching a Service Plan

Fetching of a `service plan` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_plans/:service_plan_id`

`:service_plan_id` MUST be the ID of a previously created plan.

#### Response Body

##### Service Plan Object

:warning: TODO

```json
{  
  "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "plan-name",
  "broker_id": "7905b30e-cd9e-4d8a-adc8-1f644e49dae5",
  "plan": {
    "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
    "name": "plan-name",
    "free": false,
    "description": "description",
    "service_id": "1ccab853-87c9-45a6-bf99-603032d17fe5",
    "extra": null,
    "unique_id": "1bc2884c-ee3d-4f82-a78b-1a657f79aeac",
    "public": true,
    "active": true,
    "bindable": true,
    ...
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
    }
  },
  "created_at": "2016-06-08T16:41:22Z",
  "updated_at": "2016-06-08T16:41:26Z",
  "labels": {
  }
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Service Plan ID. | 
| name* | string | Service Offering name. |
| broker_id* | string | The ID of the broker that provides this Service Plan. | 
| plan* | object | The Service Plan object as provided by the broker. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation in ISO-8601 format. |
| updated_at | string | The time of the last update in ISO-8601 format. |

\* Fields with an asterisk are REQUIRED.

### Listing Service Plans

Listing `service plans` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Route

`GET /v1/service_plans`

#### Response Body

:warning: TODO

```json
{  
  "has_more_items": true,
  "num_items": 732,
  "items": [  
    {  
      "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
      "name": "plan-name",
      "plan": {
        "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
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

## Service Visibility Management

There are currently ongoing discussions as to how platform and service visilibities should be handled in Service Manager.
:warning: TODO: Add content here.

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
| token_issuer_url* | string | URL of the token issuer. The token issuer MUST have a public endpoint `/.well-known/openid-configuration` as specified by the [OpenID Provider Configuration](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig). |

\* Fields with an asterisk are REQUIRED.

## OSB Management

The OSB Management API is an implementation of the [OSB API specification](https://github.com/openservicebrokerapi/servicebroker). It enables the Service Manager to act as a central service broker and be registered as one in the  platforms that are associated with it (meaning the platforms that are registered in the Service Manager). The Service Manager also takes care of delegating the OSB calls to the registered brokers (meaning brokers that are registered in the Service Manager) that should process the request. As such, the Service Manager acts as a platform for the actual (registered) brokers.

### Request 

The OSB Management API prefixes the routes specified in the OSB spec with `/v1/osb/:broker_id`.

`:broker_id` is the ID of the broker that the OSB call is targeting. The Service Manager MUST forward the call to this broker. The `broker_id` MUST be a globally unique non-empty string.

When a request is send to the OSB Management API, after forwarding the call to the actual broker but before returning the response, the Service Manager MAY alter the headers and the body of the response. For example, in the case of `/v1/osb/:broker_id/v2/catalog` request, the Service Manager MAY, amongst other things, add additional plans (reference plan) to the catalog.

In its role of a platform for the registered brokers, the Service Manager MAY define its own format for `Context Object` and `Originating Identity Header` similar but not limited to those specified in the [OSB spec profiles page](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md).

## Credentials Object

This specification does not limit how the Credentials Object should look like as different authentication mechanisms can be used. Depending on the used authentication mechanism, additional fields holding the actual credentials MAY be included.

**Note:** The following structure of the credentials object does not apply for Service Binding credentials. Service Binding credentials are provided by the Service Broker and MAY be free form as long as they comply with the OSB specification.

| Field | Type | Description |
| ----- | ---- | ----------- |
| basic | [basic credentials](#basic-credentials-object) | Credentials for basic authentication |
| token | string | Bearer token |

_Exactly one_ of the properties `basic` or `token` MUST be provided.

### Basic Credentials Object

| Field | Type | Description |
| ----- | ---- | ----------- |
| username* | string | username |
| password* | string | password |

\* Fields with an asterisk are REQUIRED.


## Status Object

|  Field | Type | Description |
| -------------- | ---- | ----------- |
| operation_id* | string | The ID of the operation. |
| state* | string | Valid values are `in progress`, `succeeded`, and `failed`. While `"state": "in progress"`, the Platform SHOULD continue polling. A response with `"state": "succeeded"` or `"state": "failed"` MUST cause the Platform to cease polling. |
| description | string | A user-facing message that can be used to tell the user details about the status of the operation. |
| start_time* | string | The time of operation start in ISO-8601 format. |
| end_time | string | The time of operation end in ISO-8601 format. This field SHOULD be present if `"state": "succeeded"` or `"state": "failed"`. |
| entity_id | string | The ID of the entity. It MUST be present for update and delete requests. It MUST also be present when `"state": "succeeded"`. It SHOULD be present for create operation as soon as the ID of new entity is known. |
| error | error object | An error object describing why the operation has failed. This field SHOULD be present if `"state": "failed"` and MUST NOT be present for other states. |

\* Fields with an asterisk are REQUIRED.

```json
{
  "operation_id": "42fcdf1f-79bc-43e1-8865-844e82d0979d",
  "state": "in progress",
  "description": "working on it",
  "start_time": "2016-07-09T17:50:00Z",
  "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457"
}
```

```json
{
  "operation_id": "c7880869-e1e8-403a-b57c-1396f5c89239",
  "state": "failed",
  "description": "deletion failed",
  "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457",
  "start_time": "2016-07-09T17:48:01Z",
  "end_time": "2016-07-09T17:48:22Z",
  "error" : {
    "error": "PermissionDenied",
    "description": "User has no permission to delete the platform entry."
  }
}
```

## Labels Object

A label is a key-value pair that can be attached to a resource. The key MUST be string; the value MUST be an array of strings. Service Manager resources MAY have any number of labels represented by the `labels` field.

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

Label names SHOULD only consist of alphanumeric characters, periods, hyphens, and MUST NOT contain any white spaces. Label names that contain an equals character ('`=`') CANNOT be used in label queries.  
Labels names SHOULD NOT be longer than 100 characters. The Service Manager MAY reject labels with longer names. 

### Patching Labels

The PATCH APIs of the resources that support labels MUST support the following `label operations` in order to update labels and label values.

| Operation | Description |
| --------- | ----------- |
| add | Adds a new label with the name in `label`. The `value` MUST be a string or an array of strings. If the label already exists, the operation fails as a `409 Conflict`. |
| add_values | Appends a new value to a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails as `400 Bad Request`. If the value already exists, the operation does nothing. |
| replace | Replaces a all values of a label with new values. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails as `400 Bad Request`. |
| remove | Removes a label. If the label does not exist, the operation fails with `400 Bad Request`. |
| remove_values | Removes a value from a label. The `value` MUST be a string or an array of strings. If the label does not exist, the operation fails with `400 Bad Request`. |

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

## Errors

When a request to the Service Manager fails, it MUST return an
appropriate HTTP response code. Where the specification defines the expected
response code, that response code MUST be used.

The response body MUST be a valid JSON Object.
For error responses, the following fields are defined. The Service Manager MAY
include additional fields within the response.

| Response Field | Type | Description |
| --- | --- | --- |
| error* | string | A single word that uniquely identifies the error cause. If present, MUST be a non-empty string with no whitespace. It MAY be used to identify the error programmatically on the client side. See also the [Error Codes](#error-codes) section. |
| description | string | A user-facing error message explaining why the request failed. If present, MUST be a non-empty string. |
| broker_error | string | If the upstream broker returned an error (`"error": "BrokerError"`), this field holds the broker error code. This field MUST NOT be present if the error was caused by something else. |
| broker_http_status | integer | If the upstream broker returned an error (`"error": "BrokerError"`), this field holds the HTTP status code of that error. This field MUST NOT be present if the error was caused by something else. |
| id | string | If a delete operations fails, the this field MUST contain the ID of the object that couldn't be deleted. If the `cascade` flag was set, this ID might be the ID of a linked entity. |
| retryable | boolean | If `true`, the client MAY retry the request at a later point in time. If `false`, the client SHOULD not retry the request as it will not be successful. Defaults to `true`. |

\* Fields with an asterisk are REQUIRED.

Example:

```json
{
  "error": "Unauthorized",
  "description": "The supplied credentials could not be authorized"
}
```

### Error Codes

There are failure scenarios described throughout this specification for which
the `error` field MUST contain a specific string. Service Broker authors MUST
use these error codes for the specified failure scenarios.

| Error | Status Code | Reason | Expected Action |
| --- | --- | --- | --- |
| BrokerError | xxx | The upstream broker returned an error. | |
| BadRequest | 400 | Malformed or missing mandatory data. This error SHOULD only be used if there is no other, more specific defined error. | Retry with corrected input data. |
| InvalidLabelName | 400 | The label name is invalid.  | Retry with a different label name. |
| UnknownLabel | 400 | The label doesn't exist.  | |
| ProtectedLabel | 400 | The label values cannot be changed.  | |
| InvalidLabelQuery | 400 | The label query is invalid.  | Retry with corrected label query. |
| InvalidFieldQuery | 400 | The field query is invalid.  | Retry with corrected field query. |
| UnsupportedFieldQuery | 400 | The field query contains a field that is not queryable.  | |
| InvalidMaxItems | 400 | The `max_items` parameter is not a positive number. | |
| InvalidSkipCount | 400 | The `skip_count` parameter is not a positive number. | |
| InvalidPagingParameters | 400 | The `skip_count` and the `last_id` parameters are both provided. | |
| DependantEntities | 400 | The entity cannot be deleted because other entities depend on it.  | Set the `cascade` or `force` flag. |
| Unauthorized | 401 | Unauthenticated request. | Provide credentials or a token. |
| Forbidden | 403 | The current user has no permission to execute the operation. | Retry operation with a different user. | 
| NotFound | 404 | Entity not found or not visible to the current user. | |
| IDConflict | 409 | An entity with this ID already exists. | Retry creation with another ID. |
| NameConflict | 409 | An entity with this name already exists. | Retry creation with another name. |
| LabelConflict | 409 | A label with this name already exists. | |
| Gone | 410 | There is no data about the operation anymore. | |
| ConcurrentOperation | 422 | The entity is already processed by another operation. | Retry after the currently running operation is finished. |

## Content Type

All requests and responses defined in this specification with accompanying bodies SHOULD contain a `Content-Type` header set to `application/json`. If the `Content-Type` is not set, Service Brokers and Platforms MAY still attempt to process the body. If a Service Broker rejects a request due to a mismatched Content-Type or the body is unprocessable it SHOULD respond with `400 Bad Request`.

## Mitigating Orphans

Service Manager MUST also handle the orphan mitigation process as described in the [Orphan Mitigation section](https://github.com/openservicebrokerapi/servicebroker/blob/master/spec.md#orphan-mitigation) of the OSB spec for Service Instances and Binding that have been created by the Service Manager. How this is done is an implementation detail.

The Service Manager MAY create an operation status when the orphan mitigation process (deletion of the Service Instance or Binding) is running. This allows users to track the progress and potentially failed attempts.