# Service Manager API

## Table of Contents

- [Overview](#overview)
- [Terminology and Definitions](#terminology-and-definitions)
- [Data Formats](#data-formats)
- [Localization](#localization)
- [Asynchronous Operations](#asynchronous-operations)
- [General Resource Management](#general-resource-management)
  - [Creating a Resource Entity](#creating-a-resource-entity)
  - [Fetching a Resource Entity](#fetching-a-resource-entity)
  - [Listing all Resource Entities of a Resource Type](#listing-all-resource-entities-of-a-resource-type)
  - [Updating a Resource Entity](#updating-a-resource-entity)
  - [Patching a Resource Entity](#patching-a-resource-entity)
  - [Deleting a Resource Entity](#deleting-a-resource-entity)
  - [Getting an Operation Status](#getting-an-operation-status)
  - [Getting Entity Operations](#getting-entity-operations)
- [Resource Types](#resource-types)
- [Entity Relationships](#entity-relationships)
- [Platform Management](#platform-management)
  - [Registering a Platform](#registering-a-platform)
  - [Fetching a Platform](#fetching-a-platform)
  - [Listing Platforms](#listing-platforms)
  - [Updating a Platform](#updating-a-platform)
  - [Patching a Platform](#patching-a-platform)
  - [Deleting a Platform](#deleting-a-platform)
- [Service Broker Management](#service-broker-management)
  - [Registering a Service Broker](#registering-a-service-broker)
  - [Fetching a Service Broker](#fetching-a-service-broker)
  - [Listing Service Brokers](#listing-service-brokers)
  - [Updating a Service Broker](#updating-a-service-broker)
  - [Patching a Service Broker](#patching-a-service-broker)
  - [Deleting a Service Broker](#deleting-a-service-broker)
- [Service Instance Management](#service-instance-management)
  - [Provisioning a Service Instance](#provisioning-a-service-instance)
  - [Fetching a Service Instance](#fetching-a-service-instance)
  - [Listing Service Instances](#listing-service-instances)
  - [Updating a Service Instance](#updating-a-service-instance)
  - [Patching a Service Instance](#patching-a-service-instance)
  - [Deleting a Service Instance](#deleting-a-service-instance)
- [Service Binding Management](#service-binding-management)
  - [Creating a Service Binding](#creating-a-service-binding)
  - [Fetching a Service Binding](#fetching-a-service-binding)
  - [Listing Service Binding](#listing-service-bindings)
  - [Updating a Service Binding](#updating-a-service-binding)
  - [Patching a Service Binding](#patching-a-service-binding)
  - [Deleting a Service Binding](#deleting-a-service-binding)
- [Service Offering Management](#service-offering-management)
  - [Fetching a Service Offering](#fetching-a-service-offering)
  - [Listing Service Offerings](#listing-service-offerings)
- [Service Plan Management](#service-plan-management)
  - [Fetching a Service Plan](#fetching-a-service-plan)
  - [Listing Service Plans](#listing-service-plans)
- [Service Visibility Management](#service-visibility-management)
  - [Creating a Visibility](#creating-a-visibility)
  - [Fetching a Visibility](#fetching-a-visibility)
  - [Listing All Visibilities](#listing-all-visibilities)
  - [Deleting a Visibility](#deleting-a-visibility)
  - [Updating a Visibility](#updating-a-visibility)
- [Information Management](#information-management)
- [OSB Management](#osb-management)
- [Credentials Object](#credentials-object)
- [Status Object](#status-object)
- [Labels Object](#labels-object)       
- [Errors](#errors)
- [Mitigating Orphans](#mitigating-orphans)

## Overview

The Service Manager API defines a REST interface that allows the management of Platforms, Service Brokers, Service Offerings, Service Plans, service instances and service bindings from a central place. The Service Manager API can be split into three groups:
- A Service Manager Admin API to manage Service Brokers and attached Platforms.
- A Service Controller API that allows the Service Manager to act as an OSB Platform for Service Brokers that are registered in Service Manager ("Service Manager as a Platform").
- An OSB API which allows the Service Manager to act as a Service Broker for Platforms that are registered in Service Manager ("Service Manager as a Broker"). The latter implements the [Open Service Broker (OSB) API](https://github.com/openservicebrokerapi/servicebroker/).

One of the access channels to the Service Manager is via the `smctl` CLI. The API should play nice in this context.


## Terminology and Definitions

This document inherits the terminology from the Service Manager specification and [Open Service Broker API](https://github.com/openservicebrokerapi/servicebroker/) specification.

Additionally, the follow terms and concepts are use:

* *ID*: An ID is globally unique identifier. An ID MUST NOT be longer than 50 characters and SHOULD only contain characters from the "Unreserved Characters" as defined by [RFC3986](https://tools.ietf.org/html/rfc3986#section-2.3). In other words: uppercase and lowercase letters, decimal digits, hyphen, period, underscore and tilde. Using a GUID is RECOMMENDED.
* *CLI-friendly name*: A CLI-friendly name is a short string that SHOULD only use lowercase alphanumeric characters, periods, hyphens, and no white spaces. A name MUST NOT exceed 255 character, but it is RECOMMENDED to keep it much shorter -- imagine a user having to type it as an argument for a longer command.
* *Description*: A description is a human readable string, which SHOULD NOT exceed 255 characters. If a description is longer than 255 characters, the Service Manager MAY silently truncate it.

## Data Formats

The data format for all Service Manager endpoints is [JSON](https://json.org). That implies that all strings are Unicode strings.

The Service Manager deals with date-time values in some places. Because JSON lacks a date-time data type, date-time values are encoded as strings, following ISO 8601. The only supported date-time format is: `yyyy-mm-ddThh:mm:ss.s[Z|(+|-)hh:mm]`

### Content Type

All requests and responses defined in this specification with accompanying bodies SHOULD contain a `Content-Type` HTTP header set to `application/json`. If the `Content-Type` is not set, Service Brokers and Platforms MAY still attempt to process the body. If a Service Broker rejects a request due to a mismatched `Content-Type` or the body is unprocessable it SHOULD respond with `400 Bad Request`.

## Localization

Many entities and errors contain human readable display names and descriptions. (The display name field is often called `displayName`. The description field is called `description` in most cases.)  
 If a clients provides an `Accept-Language` HTTP header and the Service Manager has a localized, matching display name or description string, it SHOULD provide the localized string. If no matching display name and/or description is available, the Service Manager MUST fall back to a default value, which SHOULD NOT be an empty string.

Whenever a client provides a value for a `displayName` or `description` field, for example when an entity is created, updated or patched, the client MAY also provide an additional object called `displayName--i18n` respectively `description--i18n`. These objects contains translations of the default display name and description that is provided in the `displayName` respectively `description` field.

A client MUST NOT provide a `displayName--i18n` object without an accompanied `displayName` field. A `displayName` field without an accompanied `displayName--i18n` object, removes existing all display name translations.

A client MUST NOT provide a `description--i18n` object without an accompanied `description` field. A `description` field without an accompanied `description--i18n` object, removes existing all description translations.

The keys within the `displayName--i18n` or `description--i18n` object SHOULD be either ISO 639-1 language codes (for example "de") or ISO 639-1 language codes followed by a hyphen ('`-`') followed by a ISO 3166 country code (for example "de-CH"). A key MUST NOT be empty or only contain white spaces.  
The values SHOULD be non-empty translations of the `displayName` respectively `description` field value and MUST follow the same rules and length restrictions of the `displayName` field respectively  the `description` field.

```json
{
  ...
  "description": "Subway Schedule Service Broker.",
  "description--i18n": {
    "en-GB": "Underground Schedule Service Broker.",
    "de": "U-Bahn Fahrplan Service Broker."
  }
  ...  
}
```

The Service Manager MAY store and use all or a subset of the entries in the `displayName--i18n` and `description--i18n` objects or MAY ignore these objects completely.


## Authentication an Authorization

Unless there is some out of band communication and agreement between a Service Manager client and the Service Manager, a client MUST authenticate with the Service Manager using OAuth 2.0 (the `Authorization:` header) on every request. 

The Service Manager MUST return a `401 Unauthorized` response if the authentication fails.

The Service Manager MUST return a `403 Forbidden` response if the client is not authorized to perform the requested operation.

In both cases, the response body SHOULD follow the [Errors](#errors) section.

This specification does not define any permission model. Authorization checks are Service Manager implementation specific. However, the Service Manager SHOULD follow these basic guidelines:

* If a user is allowed to update or delete an entity, the user SHOULD also be allowed to fetch and list the entity and to see the status of the entity.
* If a user is allowed to see an entity, the user SHOULD have access to *all* fields and labels of the entity.
* The Service Manager MAY restrict write access to some fields and labels. There is no way for the client to find out in advance which data can be set and updated.

## Asynchronous Operations

The Service Manager APIs for creating, updating, and deleting entities MAY work asynchronously. When such an operation is triggered, the Service Manager MAY respond with `202 Accepted` and a `Location header` specifying a URL to obtain the [operation status](#status-object). A Service Manager client MAY then use the Location header's value to [poll for the status](#getting-an-operation-status). Once the operation has finished  (successfully or not), the client SHOULD stop polling. The Service Manager keeps and provides [operation status](#status-object) for certain period of time after the operation has finished.
The Service Manager MAY decide to execute operations synchronously. In this case it responses with `200 Ok`, `201 Created`, or `204 No Content`, depending on the operation.

### Concurrent Mutating Requests

Service Manager MAY NOT support concurrent mutating operations on the same resource entity. If a resource with type `:resource_type` and ID `:resource_id` is currently being created, updated, patched, or deleted and this operation is in progress, then other mutating operation MAY fail on the resource of type `:resource_type` and ID `:resource_id` until the one that is currently in progress finishes. If the Service Manager receives a concurrent mutating request that it currently cannot handle due to another operation being in progress for the same resource entity, the Service Manager MUST reject the request and return HTTP status `422 Unprocessable Entity` and a meaningful [error](#errors).
The client MAY retry the request after the currently running operation has finished.

## General Resource Management

The following section generalizes how Service Manager resources are managed. A `resource_type` represents one set of resource entities (for example service brokers). A `resource_entity` represents one record of a resource type (for example one service broker record).

### Creating a Resource Entity

#### Request

##### Route

`POST /v1/:resources_type`

`:resources_type` MUST be a valid Service Manager resource type.

##### Body

The body MUST be a valid JSON Object.

Some APIs MAY allow passing in the resource entity `id` (that is the ID to be used to uniquely identify the resource entity) for backward compatibility reasons. If an `id` is not passed as part of the request body, the Service Manager takes care of generating one.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 201 Created | MUST be returned if the resource has been created. |
| 202 Accepted | MUST be returned if a resource creation is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. |
| 409 Conflict | MUST be returned if a resource with the same `name` or `id` already exists. |
| 422 Unprocessable Entity | MUST be returned if another operation for a resource with the same `name` or `id` is already in progress. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

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


#### Fields and Labels Parameters

Some entity representations are rather large and most client scenarios only require a specific subset of the data. The query parameters `fields` and `labels` allow a client to specify, which data should be returned.

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| fields | string | A comma separated list of top-level fields that MUST be returned. The Service Manager MAY return additional fields. Fields that don't exist at the entity MUST be ignored. If this parameter is missing, the Service Manager provides a default set of fields. |
| labels | string | A comma separated list of labels that MUST be returned, if they exist at the entity. If this parameter is missing and the `label` field has not been excluded, all labels MUST be returned. If the `labels` field is excluded from the response (because it's not part of the default field set or it has not been specified in the `fields` parameter), the `labels` field SHOULD NOT be provided even if this parameter is set. |

Example: `GET /v1/service_instances/aaa37597-9439-4b9b-be90-5efa8237d579?fields=id,name,service_id,parameters,labels`


#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing, if the creation operation is still in progress, or if the user is not allowed to know this resource. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Body

The response body MUST be a valid JSON Object. Each resource API in this document should include a relevant example.

In case of an ongoing asynchronous update or patch of the resource entity, this operation MUST return the old fields' values (the one known prior to the update as there is no guarantee if the update will be successful).

### Listing All Resource Entities of a Resource Type

Returns all or a subset of the resource entities of this resource type.

#### Request

##### Route

`GET /v1/:resource_type`

`:resources_type` MUST be a valid Service Manager resource type.

#### Fields and Labels Parameters

This endpoint MUST also support the `fields` and `labels` query parameters that are defined for [fetching an entity](#fetching-a-resource-entity). These parameters refer to the entities in the result set.


#### Filtering Parameters

There are two types of filtering.

1. Filtering based on top-level resource fields.
2. Filtering based on labels.

Filtering can be controlled by the following query parameters:

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| fieldQuery | string | Filters the response based on the field query. Only items that have field values matching the provided field query will be returned. If present, MUST be a non-empty string. |
| labelQuery | string | Filters the response based on the label query. Only items that have label values matching the provided label query will be returned. If present, MUST be a non-empty string. |

  Field query example: `GET /v1/service_instances?fieldQuery=service_plan_id+eq+'bvsded31-c303-123a-aab9-8crar19e1218'` would return all service instances with a service plan ID that equals `bvsded31-c303-123a-aab9-8crar19e1218`.

  Label query example: `GET /v1/service_instances?labelQuery=context_id+eq+'ad8cddb0-4679-43bf-89bc-357e9a638f30'` would return all service instances with a label `context_id` that has a value `ad8cddb0-4679-43bf-89bc-357e9a638f30`.

##### Filter Syntax and Rules

The Service Manager SHOULD support field queries on top-level fields with string and boolean values and MAY support fields with integer and date-time values. The interpretation of other value types or object is implementation specific. In general, the Service Manager SHOULD reject field queries for all other value types.

The Service Manager MAY also support field queries on nested fields. If so, the path to the field MUST be separated by a dot ('`.`'). Elements of an array are addressed with the index after the field name in square brackets('`[]`'). For example, a path could look like this: `credentials[0].basic.username`.

A BNF-like definition of a query looks like this:
```
query := predicate | predicate "and" predicate
predicate := comparison_predicate | in_predicate | exists_predicate

comparison_predicate := (field | label) comp_op literal
comp_op := "eq" | "en" | "ne" | "nn" | "gt" | "lt" | "ge" | "le"
  
in_predicate := (field | label) ("in" | "notin") "(" literals ")"

exists_predicate: = label ("exists" | "notexists")
  
field := !! field name or field path
label := !! label name

literals := literal ["," literals]
literal := string_literal | boolean_literal | integer_literal | datetime_literal | "null"
```

  * `string_literal`: String values  MUST be enclosed in single quotes ('`'`'). Single quotes in strings MUST be encoded with another single quote ('`''`').
  * `boolean_literal`: Boolean values MUST be either '`true`' or '`false`' and MUST NOT be enclosed in quotes. 
  * `integer_literal`: Integer values MUST be only consist of digits with one optional leading '`+`' or '`-`' sign.
  * `datetime_literal`: Date-time values MUST follow ISO 8601 and MUST NOT be enclosed in quotes. See also the [Data Formats](#data-formats) section.
  * "`null`": In a field query, this is this the `null` value. In a label query, it checks the existence of a label. This value MUST only be use with the `eq` or `ne` operands.

The Service Manager MUST support the following operators:

| Operator | Field Query | Label Query |
| -------- | ----------- | ----------- |
| eq | Evaluates to true if the field value matches the literal. False otherwise. | Evaluates to true if the label exists and one label value matches the literal. False otherwise. |
| en | Evaluates to true if the field value matches the literal or if the field value is `null`. False otherwise. | Evaluates to true if the label exists and one label value matches the literal or if the label doesn't exist. False otherwise. |
| ne | Evaluates to true if the field value does not matches the literal. False otherwise. | Evaluates to true if the label exists and no label value matches the literal. False otherwise. |
| nn | Evaluates to true if the field value does not matches the literal or if the field value is `null`. False otherwise. | Evaluates to true if the label exists and no label value matches the literal or if the label doesn't exist. False otherwise. |
| in | Evaluates to true if the field value matches at least one value in the list of literals. False otherwise. | Evaluates to true if the label exists and at least a label value matches one value in the list of literals. False otherwise. |
| notin | Evaluates to true if the field value does not match any value in the list of literals. False otherwise. | Evaluates to true if the label exists and no label value matches any value in the list of literals. False otherwise. |
| exists | n/a | Evaluates to true if the label exists. False otherwise. |
| notexists | n/a | Evaluates to true if the label doesn't exist. False otherwise. |
| and | Evaluates to true if both the left and right operands evaluate to true. False otherwise. ||

Additionally, the Service Manager MAY support one or multiple of the following operators for field queries:

| Operator | Field Query |
| -------- | ----------- |
| gt | Evaluates to true if the field value is greater than the literal. False otherwise. |
| ge | Evaluates to true if the field value is greater or equal than the literal. False otherwise. |
| lt | Evaluates to true if the field value is less than the literal. False otherwise. |
| le | Evaluates to true if the field value is less or equal than the literal. False otherwise. |

Label and field queries MAY be combined. The returned list MUST only contain entries that match both queries.

##### Query examples:

* List all bindings of the plan "small" or "medium" of service "mysql" provided by the broker with the ID "f85bcbd3-6c8b-43f0-a019-7f0a1ec5dba4":  
  Field query: `broker_id eq 'f85bcbd3-6c8b-43f0-a019-7f0a1ec5dba4' and service_name eq 'mysql' and plan_name in ('small', 'medium')`

* List all instances of service "postgresql" that are managed by the Service Manager and that are not orphans:  
  Field query: `platform_id eq null and service_name eq 'postgresql' and orphan ne true`

* List all Platforms of type "kubernetes" that are labeled as "dev" Platform (assuming there is a label called "purpose"):  
  Field query: `type eq 'kubernetes'`  
  Label query: `purpose eq 'dev'`

#### Paging Parameters

All `List` endpoints MUST return the list of entities ordered by creation date and entity ID.
Clients define the begin of the result set by providing the last entity ID of the previous page or no last entity ID to retrieve the first page. Clients control the size of the result set by setting the `max_items` parameter.
The Service Manager MUST provide an [appropriate error](#errors) if the provided last entity ID cannot be found. In this case, the client has to reiterate the list from the beginning.

Paging can be controlled by the following query string parameters: 

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| max_items | int | the maximum number of items to return in the response. The server MUST NOT exceed this maximum but MAY return a smaller number of items than the specified value. The server SHOULD NOT return an error if `max_items` exceeds the internally supported page size. It SHOULD return a smaller number of items instead. If the client sets `max_items` to 0, it is assumed that the client is only interested in the total number of items. The default is implementation specific. |
| last_id | string | the ID of the last entity of the previous page. The first page is requested by either not providing this parameter or providing an empty string. |

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned upon successful retrieval of the resource entities. The expected response body is below. |
| 400 Bad Request | MUST be returned if the value of the `max_items` parameter is a negative number. |
| 404 NotFound | MUST be returned if the `last_id` parameter references an unknown or for the current user invisible entity. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).


##### Body

The response body MUST be a valid JSON Object.

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| has_more_items* | boolean | `true` if the list contains additional items after those contained in the response. `false` otherwise. If `true`, a request with a larger `max_items` value is expected to return additional results (unless the list has changed or `max_items` exceeds the internally supported page size). |
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

`PUT /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Body

The body MUST provide the same data and structure that is used for creating an entity of this resource type.
Labels that are managed by the Service Manager (or a plugin) SHOULD not be provided by the client. If they are provided, the Service Manager SHOULD ignore them.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the resource has been updated. |
| 202 Accepted | MUST be returned if a resource updating is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or attempting to null out mandatory fields. |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. |
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. |
| 422 Unprocessable Entity | MUST be returned if another operation in already in progress. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).


##### Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Location | string | An URL from where the [status](#status-object) of the operation can be obtained. This header MUST be present if the status `202 Accepted` has been returned and MUST NOT be present for all other status codes. |

##### Body

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | Representation of the updated entity. The returned JSON object MUST be the same that is returned by the corresponding [fetch endpoint](#fetching-a-resource-entity). |
| 202 Accepted | The initial [Status Object](#status-object). |
| 4xx or 5xx | An [Error Object](#errors). |

### Patching a Resource Entity

#### Request

##### Route

`PATCH /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Body

The body MUST be a valid JSON object. Each resource API in this document should include a relevant example.

The body MUST provide the same data and structure that is used for creating an entity of this resource type (except for the `label` object), but all fields are OPTIONAL. Fields that are not provided, MUST NOT be changed. Fields that are explicitly supplied a `null` value MUST be nulled out provided that they are not mandatory for the resource type.

Patching the resource labels is specified in the [Patching Labels section](#patching-labels).

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the resource has been updated. |
| 202 Accepted | MUST be returned if a resource updating is successfully initiated as a result of this request. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data or attempting to null out mandatory fields. |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. |
| 409 Conflict | MUST be returned if a resource with a different `id` but the same `name` is already registered with the Service Manager. |
| 422 Unprocessable Entity | MUST be returned if another operation in already in progress. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Location | string | An URL from where the [status](#status-object) of the operation can be obtained. This header MUST be present if the status `202 Accepted` has been returned and MUST NOT be present for all other status codes. |

##### Body

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | Representation of the updated entity. The returned JSON object MUST be the same that is returned by the corresponding [fetch endpoint](#fetching-a-resource-entity). |
| 202 Accepted | The initial [Status Object](#status-object). |
| 4xx or 5xx | An [Error Object](#errors). |

### Deleting a Resource Entity

#### Request

##### Route

`DELETE /v1/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

##### Parameters

| Query-String Field | Type | Description |
| ---- | ---- | ----------- |
| cascade | boolean | Some entities cannot be deleted if other associated entities exist. For example, a service instance can only be deleted if there are no associated service bindings. This parameter allows cascade deletion of entities that are associated with the entity before deleting the actual entity. *A cascading delete MAY not be an atomic operation!* If the deletion of an associated entity fails, this operations fails, but other associated entities might have already been deleted. If this flag is combined with the `force` flag, the Service Manager will not stop if the deletion of an associated entity fails. It will try to delete as many associated entities as possible as well as the entity itself. Defaults to `false`. |
| force | boolean | Whether to force the deletion of the entity from the Service Manager. The Service Manager tries to deprovision instances and bindings if necessary (best effort), but even if that fails the, the entity is removed from data store. Associated entities are not deleted by default, but this flag can be combined with the `cascade` flag. *Using this flag may result in inconsistent data and should be used with care!* Defaults to `false`. |

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the resource has been deleted. The body MUST a non-empty, valid JSON object. If no data should be be returned from the Service Manager, the status code `204 No Content` SHOULD be used. |
| 202 Accepted | MUST be returned if a resource deletion is successfully initiated as a result of this request. |
| 204 No Content | MUST be returned if the resource has been deleted and there is no additional data provided by the Service Manager. |
| 400 Bad Request | MUST be returned if the request is malformed or missing mandatory data. |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. |
| 409 Conflict | MUST be returned if associated entities exist and neither the `cascade` nor the `force` flags are set. |
| 422 Unprocessable Entity | MUST be returned if another operation in already in progress. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

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

`GET /v1/status/:status_id`

`:status_id` is an opaque status identifier.

#### Parameters

None.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the status is available. |
| 410 Gone | MUST be returned if the requested status doesn't exist or if the user is not allowed to know this status. The client SHOULD cease polling. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Response Headers

| Header | Type | Description |
| ------ | ---- | ----------- |
| Retry-After | integer | The number of seconds to wait before checking the status again. This header SHOULD only be provided if the operation is still in progress. |

##### Response Body

If the status code is 200, the response body MUST be a [Status Object](#status-object).


### Getting Entity Operations


#### Request

##### Route

`GET /v1/status/:resource_type/:resource_entity_id`

`:resources_type` MUST be a valid Service Manager resource type.

`:resource_entity_id` MUST be the ID of a previously created resource entity of this resource type.

#### Response

| Status Code | Description |
| ----------- | ----------- |
| 200 OK | MUST be returned if the request execution has been successful. The expected response body is below. |
| 404 Not Found | MUST be returned if the requested resource is missing or if the user is not allowed to know this resource. |

Responses with a status code >= 400 will be interpreted as a failure. The response SHOULD include a user-facing message in the `description` field. For details see [Errors](#errors).

##### Body

```json
{
  "status": [
    {
      "status_id": "42fcdf1f-79bc-43e1-8865-844e82d0979d",
      "state": "in progress",
      "description": "Working on it.",
      "start_time": "2016-07-09T17:50:00.01Z",
      "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457"
    },
    {
      "status_id": "c7880869-e1e8-403a-b57c-1396f5c89239",
      "state": "failed",
      "description": "Deletion failed.",
      "start_time": "2016-07-09T17:48:01.45Z",
      "end_time": "2016-07-09T17:48:22.856Z",
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

A Service Offering has two unique keys. There is the internal service ID (`service_offering_id`) which is generated by the Service Manager when a broker is registered. If multiple brokers register the same service, each Service Offering gets a different internal service ID. And there is the pair of broker ID (`borker_id`) and service ID (`service_id`). This service ID is the ID provided in the catalog of a broker. Because multiple brokers can provide the same service and service ID, the broker ID is required to specify the Service Offering.

### Service Plans

The `service plans` API is described [here](#service-plan-management).

Definition of the semantics behind the resource name can be found in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#terminology).

### Service Visibilities

The `service visibilities` resource represents enforced visibility policies for Service Offerings and Plans. This allows the Service Manager to specify where Service Plans are visible (in which Platforms, CF orgs, etc).

The `service visibilities` API is described [here](#service-visibility-management).

## Entity Relationships

There are different types of relationships between the different entity types. This section describes these relationships and the normal (non-force and non-cascade) deletion behavior.

> All delete operation accept a `force` flag that can override the constraints defined in this section. In many cases, that will lead to an inconsistent state. Therefore, it is RECOMMENDED to restrict the use of the `force` flag to administrators.


      Broker       Visibility ---> Platform
       |  |             |             ^
       |  +----------+  |             |
       |             |  |             | 
       v             v  v             |
      Offering ----> Plan <------- Instance <---- Binding


### Service Brokers, Service Offerings and Service Plans

Service Offerings and Service Plans depend on the Service Broker that defines them. They come and go with the Service Broker.

The removal of a Service Broker MUST fail if there is still a Service Instance of a Service Plan of that broker.

### Platforms

Platforms do not depend on any other entity.

The removal of a Platform MUST fail if there is still a Service Instance associated with that Platform.

### Service Instances and Service Bindings

Service Instances depend on Service Plans (and with that on a Service Brokers) and on Platforms.
Service Bindings depend on Service Instances and therefore also on Service Brokers and Platforms.

The deprovisioning of a Service Instance MUST fail if there is at least one Service Binding of that instance.

Service Instances and Service Bindings are "owned" by a Platform. Only the Platform that created the instance or binding is allowed to update and delete those.

That is, it is not possible to delete a Service Instance through the Service Manager API that has been created by an attached Platform. Only the attached Platform can delete such an instance through the OSB API.
The delete operation of the Service Manager API only works for instances that have been created through the Service Manager API and where therefore the Service Manager is the owning Platform. 

### Visibilities

Visibilities depend on a Service Plan (and with that on a Service Broker) and a Platform. 

If either the Service Plan (the Service Broker) or the Platform goes away, all related Visibilities have to automatically vanish, too.

## Platform Management

### Registering a Platform

In order for a Platform to be usable with the Service Manager, the Service Manager needs to know about the Platforms existence. Essentially, registering a Platform would allow the Service Manager to manage the service brokers and service visibilities in this Platform.

Creation of a `platform` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/platforms`

#### Request Body

```json
{
  "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
  "name": "cf-eu-10",
  "type": "cloudfoundry",
  "description": "Cloud Foundry on AWS in Frankfurt.",
  "labels": {
    "label1": ["value1"]
  }
}
```

| Request field | Type | Description |
| ------------- | ---- | ----------- |
| id | string | ID of the Platform. If provided, MUST be unique across all Platforms registered with the Service Manager. If not provided, the Service Manager generates an ID. |
| name* | string | A CLI-friendly name of the Platform. MUST be unique across all Platforms registered with the Service Manager. MUST be a non-empty string. |
| type* | string | The type of the Platform. MUST be a non-empty string. SHOULD be one of the values defined for `platform` field in OSB [context](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md#context-object). |
| displayName | string | A human readable display name of the Platform. |
| displayName--i18n | [displayName translations](#localization) | See the [Localization](#localization) section. |
| description | string | A description of the Platform. |
| description--i18n | [description translations](#localization) | See the [Localization](#localization) section |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |

\* Fields with an asterisk are REQUIRED

### Fetching a Platform

Fetching of a `platform` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route 

`GET /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered Platform.

#### Response Body

##### Platform Object

```json
{
    "id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "name": "cf-eu-10",
    "type": "cloudfoundry",
    "description": "Cloud Foundry on AWS in Frankfurt.",
    "created_at": "2016-06-08T16:41:22.23Z",
    "updated_at": "2016-06-08T16:41:26.471Z",
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
| id* | string | ID of the Platform. |
| name* | string | Platform name. |
| type* | string | Type of the Platform. |
| displayName | string | A human readable display name of the Platform. |
| displayName--i18n | [displayName translations](#localization) | See the [Localization](#localization) section. |
| description | string | Platform description. |
| description--i18n | [description translations](#localization) | See the [Localization](#localization) section. |
| credentials | [credentials](#credentials-object) | A JSON object that contains credentials which the Service Broker Proxy (or the Platform) MUST be used to authenticate against the Service Manager. Service Manager SHOULD be able to identify the calling Platform from these credentials. |
| created_at | string | The time of the creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the `fields` query parameter.

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
      "description": "Cloud Foundry on AWS in Frankfurt.",
      "created_at": "2016-06-08T16:41:22.25Z",
      "updated_at": "2016-06-08T16:41:26.6Z",
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
      "description": "Kubernetes on GCP in us-west1.",
      "created_at": "2016-06-08T17:41:22.0Z",
      "updated_at": "2016-06-08T17:41:26.294Z",
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

`PUT /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered Platform.

##### Request Body

See [Registering a Platform](#registering-a-platform).


### Patching a Platform

Patching of a `platform` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

#### Route

`PATCH /v1/platforms/:platform_id`

`:platform_id` The ID of a previously registered Platform.

##### Request Body

See [Registering a Platform](#registering-a-platform) and [Patching Labels](#patching-labels).


### Deleting a Platform

Deletion of a `platform` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

This operation MUST fail if there are service instances associated with this Platform and neither the `force` nor the `cascade` flag are set.

If the `cascade` flag is set, the Service Manager SHOULD try to delete all service bindings and service instances that are attached to this Platform.
Using the `force` flag MAY leave service bindings and service instances in the data store and the service brokers behind.

All [Service Visibilities](#service-visibility-management) entries that belong to this `platform` resource entity are automatically removed, regardless of the `cascade` and `force` flags.

#### Route

`DELETE /v1/platforms/:platform_id`

`:platform_id` MUST be the ID of a previously registered Platform.

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
    "displayName": "My Service Broker",
    "description": "Service broker providing some valuable services.",
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
| displayName | string | A human readable display name of the service broker. |
| displayName--i18n | [displayName translations](#localization) | See the [Localization](#localization) section. |
| description | string | A description of the service broker. |
| description--i18n | [description translations](#localization) | See the [Localization](#localization) section |
| broker_url* | string | MUST be a valid base URL for an application that implements the OSB API. |
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
    "displayName": "My Service Broker",
    "description": "Service broker providing some valuable services.",
    "created_at": "2016-06-08T16:41:26.734Z.104",
    "updated_at": "2016-06-08T16:41:26.104Z",
    "broker_url": "https://service-broker-url",
    "labels": {
      "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the service broker. |
| name* | string | Name of the service broker. |
| displayName | string | A human readable display name of the service broker. |
| displayName--i18n | [displayName translations](#localization) | See the [Localization](#localization) section. |
| description | string | Description of the service broker. |
| description--i18n | [description translations](#localization) | See the [Localization](#localization) section |
| broker_url* | string | URL of the service broker. |
| created_at | string | The time of creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |
| labels* | collection of [labels](#labels-object) | Additional data associated with the service broker. MAY be an empty object. |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the `fields` query parameter.

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
      "description": "Service broker providing some valuable services.",
      "created_at": "2016-06-08T16:41:26.104Z",
      "updated_at": "2016-06-08T16:41:26.104",
      "broker_url": "https://service-broker-url",
      "labels": {
        "label1": ["value1"]
      }
    },
    {
      "id": "a62b83e8-1604-427d-b079-200ae9247b60",
      "name": "another-broker",
      "description": "More services.",
      "created_at": "2016-06-08T17:41:26.104Z",
      "updated_at": "2016-06-08T17:41:26.104Z",
      "broker_url": "https://another-broker-url",
      "labels": {
      }
    }
  ]
}
```

### Updating a Service Broker

Updating of a `service broker` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

Updating a service broker MUST trigger an update of the catalog of this service broker.

#### Route

`PUT /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Request Body

See [Registering a Service Broker](#registering-a-service-broker).


### Patching a Service Broker

Updating of a `service broker` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

Patching a service broker (even with an empty JSON object `{}`) MUST trigger an update of the catalog of this service broker.

#### Route

`PATCH /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

#### Request Body

See [Registering a Service Broker](#registering-a-service-broker) and [Patching Labels](#patching-labels).

### Deleting a Service Broker

Deletion of a `platform` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

This operation MUST fail if there are service instances associated with this service broker and neither the `force` nor the `cascade` flag are set.

If the `cascade` flag is set, the Service Manager SHOULD try to delete all service bindings and service instances that have been provided by this service broker. This MAY result in dangling data in the Platforms.
Using the `force` flag MAY leave service bindings and service instances in the data store behind. It MAY also result dangling data in the Platforms and service instances that are not accessible anymore.

#### Route

`DELETE /v1/service_brokers/:broker_id`

`:broker_id` MUST be the ID of a previously registered service broker.

## Service Instance Management

### Provisioning a Service Instance

Creation of a `service instance` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

There are two ways to specify the Service Offering of the to be provisioned Service Instance:
1. The client specifies the service ID (`service_id`) as provided by the catalog. If the current user has access to more than one broker that provides this service, the user MUST also provide the broker ID (`broker_id`). If the broker ID is necessary and not specified, the Service Manager returns an appropriate [error](#errors).
2. The client provides the Service Manager internal ID (`service_offering_id`) of the Service Offering. This ID is unique across Service Brokers even if multiple brokers provide the same service with the same Service Offering ID.

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
| service_offering_id | string | The internal ID of a Service Offering. If this field is set, the `service_id` field MUST NOT be present. |
| broker_id | string | The ID of a Service Broker. |
| service_id | string | The ID of a Service Offering as provided by the catalog. If this field is set the `service_offering_id` field MUST NOT be present. If this field is ambiguous because multiple Service Brokers provide this service, the `broker_id` field MUST be set. |
| plan_id* | string | MUST be the ID of a Service Plan. |
| parameters | object | Configuration parameters for the Service Instance. |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty array. |

\* Fields with an asterisk are REQUIRED.

**Note:** Service Manager MUST also handle [mitigating orphans](#mitigating-orphans) in the context of service instances.

### Fetching a Service Instance

Fetching of a `service instance` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

The Service Manager MAY choose to provide cached data and not to [fetch the data from the upstream broker](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-instance).


#### Route

`GET /v1/service_instances/:service_instance_id`

`:service_instance_id` MUST be the ID of a previously provisioned service instance.

##### Parameters

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| upstream | boolean | If this flag is set to `true` and if the broker [supports fetching the Service Instance data](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-instance), the Service Manager MUST get the data from the upstream broker. Otherwise, the Service Manager SHOULD ignore this flag. The Service Manager MAY use the fetched data to update its cache. |

#### Response Body

##### Service Instance Object

```json
{  
  "id": "238001bc-80bd-4d67-bf3a-956e4d543c3c",
  "name": "my-service-instance",
  "broker_id": "f08eb906-9343-45e5-9dc6-50bd4a1e21f7",
  "service_id": "31129f3c-2e19-4abb-b509-ceb1cd157132",
  "service_name": "my-service",
  "plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
  "plan_name": "small-plan",
  "platform_id": "3f04164d-6aef-4438-9bf2-08f9dd5d2edb", 
  "platform_name": "cluster-4567", 
  "parameters": {  
    "parameter1": "value1",
    "parameter2": "value2"
  },
  "labels": {  
    "context_id": [
      "bvsded31-c303-123a-aab9-8crar19e1218"
    ]
  },
  "created_at": "2016-06-08T16:41:22.345Z",
  "updated_at": "2016-06-08T16:41:26.62Z"
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Service Instance ID. | 
| name* | string | Service Instance name. |
| service_offering_id* | string | The internal ID of the Service Offering. |
| broker_id* | string | The ID of Service Broker that manages this instance. |
| service_id* | string | The ID of a Service Offering as provided by the catalog. |
| service_name | string | The name of a Service Offering. |
| plan_id* | string | The ID of the Service Plan. |
| plan_name | string | The name of the Service Plan. |
| platform_id* | string | ID of the Platform that owns this instance or `null` if the Service Manager owns it. |
| platform_name | string |The name of the Platform that owns this instance or `null` if the Service Manager owns it. |
| dashboard_url | string | The URL of a web-based management user interface for the Service Instance; we refer to this as a service dashboard. |
| parameters | object |	Configuration parameters for the Service Instance. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty array. |
| created_at | string | The time of the creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |
| orphan | boolean | If `true` the Service Instance is an orphan and will eventually be removed by the Service Manager. If `false` the Service Instance is useable. This field MUST only be present, if the Service Instance has been created by the Service Manager. |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the `fields` query parameter.

### Listing Service Instances

Listing `service instances` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

The Service Manager MAY choose to provide cached data and not to [fetch the data from the upstream brokers](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-instance).

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
      "service_offering_id": "84ea69e4-61bf-4478-a40a-c736c683d693",
      "broker_id": "f08eb906-9343-45e5-9dc6-50bd4a1e21f7",
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
      "created_at": "2016-06-08T16:41:22.129Z",
      "updated_at": "2016-06-08T16:41:26.129Z"
    }
  ]
}
```

### Updating a Service Instance

Updating of a `service instance` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PUT /v1/service_instances/:service_instance_id`

`:service_instance_id` The ID of a previously provisioned service instance.

#### Request Body

See [Provisioning a Service Instance](#provisioning-a-service-instance).

**Note:** Updating parameters works as described in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#updating-a-service-instance) in section "*Updating a Service Instance*".


### Patching a Service Instance

Patching of a `service instance` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

#### Route

`PATCH /v1/service_instances/:service_instance_id`

`:service_instance_id` The ID of a previously provisioned service instance.

#### Request Body

See [Provisioning a Service Instance](#provisioning-a-service-instance) and [Patching Labels](#patching-labels).

**Note:** Patching parameters works as described in the [OSB specification](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#updating-a-service-instance) in section "*Updating a Service Instance*".

### Deleting a Service Instance

Deletion of a `service instance` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

This operation MUST fail if there are service binding associated with this service instance and neither the `force` nor the `cascade` flag are set.

If the `cascade` flag is set, the Service Manager SHOULD try to delete all service binding that are attached to this service instance.
Using the `force` flag MAY leave service bindings in the data store and the service brokers behind. There is also no guarantee that the service instance has been successfully deprovisioned.   

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

**Note:** Service Manager MUST also handle [mitigating orphans](#mitigating-orphans) in the context of service bindings.

### Fetching a Service Binding

Fetching of a `service binding` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

The Service Manager MAY choose to provide cached data and not to [fetch the data from the upstream broker](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-binding).

#### Route

`GET /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

##### Parameters

| Query-String Field | Type | Description |
| ------------------ | ---- | ----------- |
| upstream | boolean | If this flag is set to `true` and if the broker [supports fetching the Service Binding data](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-binding), the Service Manager MUST get the data from the upstream broker. Otherwise, the Service Manager SHOULD ignore this flag. The Service Manager MAY use the fetched data to update its cache. |


#### Response Body

##### Service Binding Object

```json
{  
  "id": "138001bc-80bd-4d67-bf3a-956e4w543c3c",
  "name": "my-service-binding",
  "broker_id": "f08eb906-9343-45e5-9dc6-50bd4a1e21f7",
  "service_offering_id": "84ea69e4-61bf-4478-a40a-c736c683d693",
  "service_id": "31129f3c-2e19-4abb-b509-ceb1cd157132",
  "plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
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
  "created_at": "2016-06-08T16:41:22.213Z",
  "updated_at": "2016-06-08T16:41:26.0Z"
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | The Service Binding ID. | 
| name* | string | The Service Binding name. |
| service_offering_id* | string | The internal ID of the Service Offering. |
| broker_id* | string | The ID of Service Broker that manages this instance. |
| service_id* | string | The ID of a Service Offering as provided by the catalog. |
| service_name | string | The name of a Service Offering. |
| plan_id* | string | The ID of the Service Plan. |
| plan_name | string | The name of the Service Plan. |
| service_instance_id* | string | The Service Instance ID. |
| platform_id* | string | ID of the Platform that owns this binding or `null` if the Service Manager owns it. |
| platform_name | string |The name of the Platform that owns this binding or `null` if the Service Manager owns it. |
| binding | object | The binding returned by the Service Broker. In most cases, this object contains a `credentials` object. |
| parameters | object | Configuration parameters for the Service Binding. Service Brokers SHOULD ensure that the client has provided valid configuration parameters and values for the operation. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |
| orphan | boolean | If `true` the Service Binding is an orphan and will eventually be removed by the Service Manager. If `false` the Service Binding is useable. This field MUST only be present, if the Service Binding has been created by the Service Manager. |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the `fields` query parameter.

### Listing Service Bindings

Listing `service bindings` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

The Service Manager MAY choose to provide cached data and not to [fetch the data from the upstream brokers](https://github.com/openservicebrokerapi/servicebroker/blob/v2.14/spec.md#fetching-a-service-binding).

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
      "created_at": "2016-06-08T16:41:22.342Z",
      "updated_at": "2016-06-08T16:41:26.295Z"
    }
  ]
}
```


## Updating a Service Binding

Updating of a `service binding` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

Only the name and the labels can be changed.

#### Route

`PUT /v1/service_bindings/:service_binding_id`

`:service_binding_id` The ID of a previously created service binding.

#### Request Body

| Request field | Type | Description |
| -------------- | ---- | ----------- |
| name* | string | A non-empty binding name. |
| labels* | collection of [labels](#labels-object) | MAY be an empty object. |

\* Fields with an asterisk are REQUIRED.

## Patching a Service Binding

Updating of a `service binding` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).

Only the name and the labels can be changed.

#### Route

`PATCH /v1/service_bindings/:service_binding_id`

`:service_binding_id` The ID of a previously created service binding.

#### Request Body

| Request field | Type | Description |
| -------------- | ---- | ----------- |
| name | string | A non-empty binding name. |
| labels | array of label patches | See [Patching Labels](#patching-labels). |

\* Fields with an asterisk are REQUIRED.

### Deleting a Service Binding

Deletion of a `service binding` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

The `cascade` flag has no effect and MUST be ignored.
If the `force` flag is used, there is no guarantee that the service binding has been successfully unbind.   

#### Route

`DELETE /v1/service_bindings/:service_binding_id`

`:service_binding_id` MUST be the ID of a previously created service binding.

## Service Offering Management

As per the OSB API terminology a service offering represents the advertisement of a service that a service broker supports. Service Manager MUST expose a management API of the service offerings offered by the registered service brokers.

The Service Manager MAY add, remove, or change Service Offerings details. For example, the Service Manager MAY replace the `metadata.displayName` or `description` field value with translations based on the `Accept-Language` HTTP request header. It MAY also add a [`metadata.displayName--i18n` field](#localization) or [`description--i18n` field](#localization) or do other changes. That is, Service Offering object returned by the Service Manager MAY differ from the one provided by the upstream Service Broker.

### Fetching a Service Offering

Fetching of a `service offering` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_offerings/:service_offering_id`

`:service_offering_id` MUST be the ID of a service offering.

####  Response Body

##### Service Offering Object

```json
{  
  "id": "6310b226-f71d-4a9c-b4d6-62c14043cadf",
  "name": "my-service-offering",
  "broker_id": "7905b30e-cd9e-4d8a-adc8-1f644e49dae5",
  "service_id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "service_name": "my-service-offering",
  "service": {
    "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
    "name": "my-service-offering",
    "description": "A service offering description.",
    "metadata": {
      "displayName": "postgres",
      "longDescription": "A service offering long description."
    },
    "bindable": true,
    "plan_updateable": false,
    "instances_retrievable": false,
    "bindings_retrievable": false,
    ...
  },
  "labels": {
  },
  "created_at": "2016-06-08T16:41:22.435Z",
  "updated_at": "2016-06-08T16:41:26.891Z",
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Internal Service Offering ID. | 
| name* | string | Service Offering name. |
| broker_id* | string | The ID of the broker that provides this Service Offering. |
| service_id* | string | The ID of the Service Offering as provided by the catalog. |
| service_name* | string | The name of the Service Offering. |
| service* | object | The Service Offering object as provided by the broker, but without the `plans` field. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the fields query parameter.

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
      "service_id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "service_name": "my-service-offering",
      "service": {
        "id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
        "name": "my-service-offering",
        "description": "A service offering description.",
        "metadata": {
          "displayName": "display-name",
          "longDescription": "A service offering long description."
        },
        "service_broker_id": "0e7250aa-364f-42c2-8fd2-808b0224376f",
        "bindable": true,
        "plan_updateable": false,
        "instances_retrievable": false,
        "bindings_retrievable": false,
        ...
      },
      "created_at": "2016-06-08T16:41:22.945Z",
      "updated_at": "2016-06-08T16:41:26.525Z",
      "labels": {
      }
    },
    ...
  ]
}
```

## Service Plan Management

As per the OSB API terminology, a service plan is representation of the costs and benefits for a given variant of the service, potentially as a tier that a service broker offers. Service Manager MUST expose a management API of the service plans offered by services of the registered service brokers.

The Service Manager MAY add, remove, or change Service Plan details. For example, the Service Manager MAY replace the `metadata.displayName` or `description` field value with translations based on the `Accept-Language` HTTP request header. It MAY also add a [`metadata.displayName--i18n` field](#localization) or [`description--i18n` field](#localization) or do other changes. That is, Service Offering object returned by the Service Manager MAY differ from the one provided by the upstream Service Broker.

### Fetching a Service Plan

Fetching of a `service plan` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Route

`GET /v1/service_plans/:service_plan_id`

`:service_plan_id` MUST be the ID of a plan.

#### Response Body

##### Service Plan Object

:warning: TODO

```json
{  
  "id": "b8d6f695-7c67-48c2-be45-d3f651c26a75",
  "broker_id": "7905b30e-cd9e-4d8a-adc8-1f644e49dae5",
  "service_id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
  "service_name": "my-service-offering",
  "plan_id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
  "plan_name": "plan-name",
  "plan": {
    "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
    "name": "plan-name",
    "free": false,
    "description": "This a plan description.",
    "service_id": "1ccab853-87c9-45a6-bf99-603032d17fe5",
    "extra": null,
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
  "created_at": "2016-06-08T16:41:22.104Z",
  "updated_at": "2016-06-08T16:41:26.734Z",
  "labels": {
  }
}
```

| Response field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | Internal Service Plan ID. | 
| name* | string | Service Offering name. |
| broker_id* | string | The ID of the broker that provides this Service Plan. |
| service_id* | string | The ID of the Service Offering as provided by the catalog. |
| service_name* | string | The name of the Service Offering. |
| plan_id* | string | The ID of the Service Plan. |
| plan_name* | string | The name of the Service Plan. |
| plan* | object | The Service Plan object as provided by the broker. |
| labels* | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |
| created_at | string | The time of the creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the fields query parameter.

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
      "service_id": "138401bc-80bd-4d67-bf3a-956e4d543c3c",
      "service_name": "my-service-offering",
      "plan_id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
      "plan_name": "plan-name",
      "plan": {
        "id": "418401bc-80bd-4d67-bf3a-956e4d543c3c",
        "name": "plan-name",
        "free": false,
        "description": "This is a plan description.",
        "service_id": "1ccab853-87c9-45a6-bf99-603032d17fe5",
        "extra": null,
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
      "created_at": "2016-06-08T16:41:22.104Z",
      "updated_at": "2016-06-08T16:41:26.734Z",
      "labels": {

      }
    }
  ]
}
```

## Service Visibility Management

Visibilities in the Service Manager are used to manage which Platform sees which Service Plan. If applicable, labels MAY be attached to a visibility to further scope the access of the plan inside the Platform.

Visibilities are automatically deleted when the referenced Platform is deregistered or when the referenced Service Plan becomes unavailable.

### Creating a Visibility

Creation of a `visibility` resource entity MUST comply with [creating a resource entity](#creating-a-resource-entity).

#### Route

`POST /v1/visibilities`

#### Request Body

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
| platform_id | string | If present, MUST be the ID of an existing Platform or `null`. If missing or `null`, this means that the Service Plan is visible to all Platforms. |
| service_plan_id* | string | This MUST be the ID of an existing Service Plan. |
| labels | collection of [labels](#labels-object) | Additional data associated with the resource entity. MAY be an empty object. |

 \* Fields with an asterisk are REQUIRED.


### Fetching a Visibility

Fetching of a `visibility` resource entity MUST comply with [fetching a resource entity](#fetching-a-resource-entity).

#### Request

##### Route

 `GET /v1/visibilities/:visibility_id`

 `:visibility_id` MUST be the ID of a previously created visibility.

#### Response

##### Visibility Object

```json
{
    "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
    "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
    "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
    "created_at": "2016-06-08T16:41:22.104Z",
    "updated_at": "2016-06-08T16:41:26.734Z",
    "labels": {
        "label1": ["value1"]
    }
}
```

| Response Field | Type | Description |
| -------------- | ---- | ----------- |
| id* | string | ID of the visibility. |
| platform_id* | string | ID of the Platform for this Visibility or `null` if this Visibility is valid for all Platforms. |
| service_plan_id* | string | ID of the Service Plan for this Visibility. |
| created_at | string | The time of creation [in ISO 8601 format](#data-formats). |
| updated_at | string | The time of the last update [in ISO 8601 format](#data-formats). |
| labels* | collection of [labels](#labels-object) | Additional data associated with the Visibility. MAY be an empty object. |

\* Fields with an asterisk are provided by default. The other fields MAY be requested by the `fields` query parameter.

### Listing All Visibilities

Listing `visibilities` MUST comply with [listing all resource entities of a resource type](#listing-all-resource-entities-of-a-resource-type).

#### Request

##### Route

`GET /v1/visibilities`

##### Response Body

```json
{
  "has_more_items": false,
  "num_item": 2,
  "items": [
    {
      "id": "36931aaf-62a7-4019-a708-0e9abf7e7a8f",
      "platform_id": "038001bc-80bd-4d67-bf3a-956e4d545e3c",
      "service_plan_id": "fe173a83-df28-4891-8d91-46334e04600d",
      "created_at": "2016-06-08T16:41:22.104Z",
      "updated_at": "2016-06-08T16:41:26.734Z",
      "labels": {
        "label1": ["value1"]
      }
    },
    {
      "id": "3aaed233-7fb0-4441-becb-4a09f33265d8",
      "platform_id": null,
      "service_plan_id": "83ae38ae-ad02-4fe9-ae39-406a59cdf7e6",
      "created_at": "2016-06-09T16:41:22.104Z",
      "updated_at": "2016-06-09T16:41:26.734Z",
      "labels": {}
    }
  ]
}
```
### Updating a Visibility

Updating of a `visibility` resource entity MUST comply with [updating a resource entity](#updating-a-resource-entity).

#### Route

`PUT /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created visibility.

#### Request Body

See [Creating a Visibility](#creating-a-visibility).

### Patching a Visibility

Updating of a `visibility` resource entity MUST comply with [patching a resource entity](#patching-a-resource-entity).


#### Route

`PATCH /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created visibility.

#### Request Body

See [Creating a Visibility](#creating-a-visibility) and [Patching Labels](#patching-labels).

### Deleting a Visibility

Deletion of a `visibility` resource entity MUST comply with [deleting a resource entity](#deleting-a-resource-entity).

#### Request

##### Route

`DELETE /v1/visibilities/:visibility_id`

`:visibility_id` MUST be the ID of a previously created Visibility.

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

The OSB Management API is an implementation of the [OSB API specification](https://github.com/openservicebrokerapi/servicebroker). It enables the Service Manager to act as a central service broker and be registered as one in the  Platforms that are associated with it (meaning the Platforms that are registered in the Service Manager). The Service Manager also takes care of delegating the OSB calls to the registered brokers (meaning brokers that are registered in the Service Manager) that should process the request. As such, the Service Manager acts as a Platform for the actual (registered) brokers.

### Request 

The OSB Management API prefixes the routes specified in the OSB spec with `/v1/osb/:broker_id`.

`:broker_id` is the ID of the broker that the OSB call is targeting. The Service Manager MUST forward the call to this broker. The `broker_id` MUST be a globally unique non-empty string.

When a request is send to the OSB Management API, after forwarding the call to the actual broker but before returning the response, the Service Manager MAY alter the headers and the body of the response. For example, in the case of `/v1/osb/:broker_id/v2/catalog` request, the Service Manager MAY, amongst other things, add additional plans (reference plan) to the catalog.

In its role of a Platform for the registered brokers, the Service Manager MAY define its own format for `Context Object` and `Originating Identity Header` similar but not limited to those specified in the [OSB spec profiles page](https://github.com/openservicebrokerapi/servicebroker/blob/master/profile.md).
For example, the `Context Object` SHOULD contain an entry `instance_name` that provides the name of the Service Instance.

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

 Status objects are meant for clients. They SHOULD NOT convey any Service Manager implementation or process details or use internal terminology. Status description should be meaningful to the majority of end-users. 

| Field | Type | Description |
| -------------- | ---- | ----------- |
| status_id* | string | The status ID. |
| state* | string | Valid values are `in progress`, `succeeded`, and `failed`. While `"state": "in progress"`, the Platform SHOULD continue polling. A response with `"state": "succeeded"` or `"state": "failed"` MUST cause the Platform to cease polling. |
| description | string | A user-facing message that can be used to tell the user details about the status of the operation. |
| start_time* | string | The time of operation start [in ISO 8601 format](#data-formats). |
| end_time | string | The time of operation end [in ISO 8601 format](#data-formats). This field SHOULD be present if `"state": "succeeded"` or `"state": "failed"`. |
| entity_id | string | The ID of the entity. It MUST be present for update and delete requests. It MUST also be present when `"state": "succeeded"`. It SHOULD be present for create operation as soon as the ID of new entity is known. |
| error | error object | An error object describing why the operation has failed. This field SHOULD be present if `"state": "failed"` and MUST NOT be present for other states. |
| sub_status | array of [sub status objects](#sub-status-object) | If an operation consists of multiple steps, the Service Manager MAY provide the status of each step here. These steps SHOULD be comprehensible for the end-user and SHOULD NOT reveal any implementation specific details. For example, a cascade delete of a Service Instances may require the deletion of bindings. Each binding deletion could be such a step with its own sub-status. Also, retries MAY be recorded here. For example, the Service Manager may need multiple attempts to reach a Service Broker. Each attempt could have its own status. If present, MUST be a non-empty array. |

\* Fields with an asterisk are REQUIRED.

```json
{
  "status_id": "42fcdf1f-79bc-43e1-8865-844e82d0979d",
  "state": "in progress",
  "description": "Working on it.",
  "start_time": "2016-07-09T17:50:00.123Z",
  "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457",
  "sub_status": [
    {
      "state": "succeeded",
      "start_time": "2016-07-09T17:50:00.130Z",
      "end_time": "2016-07-09T17:50:01.003Z",
      "description": "Step one - done.",
    },
    {
      "state": "in progress",
      "start_time": "2016-07-09T17:50:01.052Z",
      "description": "Waiting...",
    }
  ]
}
```

```json
{
  "status_id": "c7880869-e1e8-403a-b57c-1396f5c89239",
  "state": "failed",
  "description": "Deletion failed.",
  "entity_id": "a67ebb30-a71a-4c23-81c6-f79fae6fe457",
  "start_time": "2016-07-09T17:48:01.724Z",
  "end_time": "2016-07-09T17:48:22.889Z",
  "error" : {
    "error": "PermissionDenied",
    "description": "User has no permission to delete the platform entry."
  }
}
```

### Sub-Status Object

| Field | Type | Description |
| -------------- | ---- | ----------- |
| state* | string | Valid values are `in progress`, `succeeded`, and `failed`.  Multiple sub-status can be in state `in progress` at the same time. The overall status is independent of sub-status. Even if one sub-status is in state `failed` the overall status might be in state `succeeded`.   |
| description | string | A user-facing message that can be used to tell the user details about this sub-status. |
| start_time* | string | The time of operation start [in ISO 8601 format](#data-formats). |
| end_time | string | The time of operation end [in ISO 8601 format](#data-formats). This field SHOULD be present if `"state": "succeeded"` or `"state": "failed"`. |
| error | error object | An error object describing why the operation has failed. This field SHOULD be present if `"state": "failed"` and MUST NOT be present for other states. |



## Labels Object

A label is a key-value pair that can be attached to a resource. The key MUST be a string. The value MUST be a non-empty array of unique strings. Label keys and values MUST be compared in a case-sensitive way. Service Manager resources MAY have any number of labels represented by the `labels` field. The set of labels is not ordered in any way.

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
        "label2Value1",
        "label2Value2"
      ]
    }
}  
```

### Label Keys and Values

Label keys SHOULD only consist of alphanumeric characters, periods, hyphens, underscores and MUST NOT contain any white spaces, equals characters ('`=`'), or commas ('`,`').
Labels keys SHOULD NOT be longer than 100 characters. The Service Manager MAY reject labels with longer names. 

Label values MUST NOT be empty strings or contain newline characters.
Label values SHOULD NOT be longer than 255 characters. The Service Manager MAY reject labels with longer values. 

### Patching Labels

The PATCH APIs of the resources that support labels MUST support update of labels and label values.

`labels` is an optional field in the request JSON. If present, it MUST be an array of objects. Each object defines a label operation using the following format:

| Field | Type | Description |
| ----- | ---- | ----------- |
| op* | string | The label operation to apply. |
| key* | string | The label key. |
| values | string array | The label values. If present, MUST NOT be empty. REQUIRED for `add` and `set` operations. |

\* Fields with an asterisk are REQUIRED.

| Operation | Description |
| --------- | ----------- |
| add | Adds a new label or new values. If a label with the given `key` does not exist already, it MUST be created with the given `values`. Otherwise, any new values MUST be added to the label. If any of the `values` already exist in the label, they MUST be ignored silently. Any existing values MUST remain unchanged. `values` field is REQUIRED. |
| set | Adds a new label or overwrites an existing one. If a label with the given `key` does not exist already, it MUST be created with the given `values`. Otherwise, all label values MUST be replaced with the given `values`. `values` field is REQUIRED. |
| remove | Removes a label or some of its values. If a label with the given `key` does not exist, the operation MUST be ignored silently. Otherwise, the given `values` MUST be removed from the specified label. Any existing label values not specified in `values`, MUST remain unchanged. If any of the `values` are not present in the label, they MUST be ignored silently. If the label remains with no values, it MUST be removed completely. If `values` field is not provided, the whole label with all its values MUST be removed. |

All operations in one request MUST be performed as one atomic change. Either all or none of them are performed.

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
    { "op": "set", "key": "label2", "values": ["test2"] },
    { "op": "remove", "key": "label3" },
  ]
...  
```

## Errors

Errors are meant for clients. They SHOULD NOT convey any Service Manager implementation details such as stack traces or use internal terminology. If debug or developer data is required, that data SHOULD be logged and SHOULD be linked via the `reference_id` with this error.

When a request to the Service Manager fails, it MUST return an appropriate HTTP response code. Where the specification defines the expected response code, that response code MUST be used.

The response body MUST be a valid JSON Object.
For error responses, the following fields are defined. The Service Manager MAY include additional fields within the response. 


| Response Field | Type | Description |
| --- | --- | --- |
| error* | string | A single word that uniquely identifies the error cause. If present, MUST be a non-empty string with no white space. It MAY be used to identify the error programmatically on the client side. See also the [Error Codes](#error-codes) section. |
| description | string | A user-facing error message explaining why the request failed. If present, MUST be a non-empty string. |
| reference_id | string | If the Service Manager logged this error somewhere, this reference ID allows the correlation of this error to the log entries. If present, MUST be a non-empty string. |
| broker_error | string | If the upstream broker returned an error (`"error": "BrokerError"`), this field holds the broker error code. This field MUST NOT be present if the error was caused by something else. |
| broker_http_status | integer | If the upstream broker returned an error (`"error": "BrokerError"`), this field holds the HTTP status code of that error. This field MUST NOT be present if the error was caused by something else. |
| entity_id | string | If a delete operations fails, the this field MUST contain the ID of the entity that couldn't be deleted. If the `cascade` flag was set, this ID might be the ID of an associated entity. |
| repeatable | boolean | If `true`, the client MAY retry the request at a later point in time. If `false`, the client SHOULD not retry the request as it will not be successful. Defaults to `true`. |
| instance_usable | boolean | If an update or deprovisioning operation failed, this flag indicates whether or not the Service Instance is still usable. If `true`, the Service Instance can still be used, `false` otherwise. This field MUST NOT be present for errors of other operations. Defaults to `true`. |

\* Fields with an asterisk are REQUIRED.

Example:

```json
{
  "error": "Unauthorized",
  "description": "The supplied credentials could not be authorized."
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
| InvalidLabelName | 400 | The label name is invalid. | Retry with a different label name. |
| ProtectedLabel | 400 | The label values cannot be changed. | |
| InvalidLabelQuery | 400 | The label query is invalid. | Retry with corrected label query. |
| InvalidFieldQuery | 400 | The field query is invalid. | Retry with corrected field query. |
| UnsupportedFieldQuery | 400 | The field query contains a field that is not queryable. | |
| InvalidMaxItems | 400 | The `max_items` parameter is not 0 or a positive number. | Retry with no or a valid `max_items` parameter. |
| AmbiguousServiceID | 400 | The service ID is ambiguous. | Add also the broker ID to the request. |
| Unauthorized | 401 | Unauthenticated request. | Provide credentials or a token. |
| Forbidden | 403 | The current user has no permission to execute the operation. | Retry operation with a different user. | 
| NotFound | 404 | Entity not found or not visible to the current user. | |
| LastIDNotFound | 404 | There is no entity that matches the `last_id` parameter. | Reiterate the list from the beginning. |
| IDConflict | 409 | An entity with this ID already exists. | Retry creation with another ID. |
| NameConflict | 409 | An entity with this name already exists. | Retry creation with another name. |
| AssociatedEntityConflict | 409 | The entity cannot be deleted because an associated entity exists. | Remove the associated entity or retry the delete operation with the `cascade` or `force` flag. |
| VisibilityAlreadyExists | 409 | A visibility for this Platform and Service Plan combination already exists. | Update visibility instead. |
| Gone | 410 | There is no data about the operation anymore. | Don't retry. |
| ConcurrentOperation | 422 | The entity is already processed by another operation. | Retry after the currently running operation is finished. |

## Mitigating Orphans

Service Manager MUST also handle the orphan mitigation process as described in the [Orphan Mitigation section](https://github.com/openservicebrokerapi/servicebroker/blob/master/spec.md#orphan-mitigation) of the OSB spec for Service Instances and Binding that have been created by the Service Manager. How this is done is an implementation detail.

The Service Manager MAY create an operation status when the orphan mitigation process (deletion of the Service Instance or Binding) is running. This allows users to track the progress and potentially failed attempts.