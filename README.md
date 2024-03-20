# Quake

A ruby ​​app made for creating and documenting stress tests in APIs.
## How to install

```bash
  bundle install
```
## How to use?

1. Clone this repository

```git
git clone https://github.com/michaelalves204/quake.git
```

2. Create a templates folder wherever you want and add a .json file containing the necessary settings

## Configuration file example

```json
{
  "type": "REST",
  "method_http": "POST",
  "base_url": "https://example-api.com",
  "endpoint": "/example/login",
  "body": {
    "email": "example_user",
    "password": "password"
   },
  "headers": {
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9"
   },
  "config": {
    "number_of_requests": 100,
    "max_threads_number": 30
  }
}
```

#### About settings

* **type**: will be the type of api on which the tests will be done
for now we support rest and graphql

* **mehotd_http**: These are the http methods, for now we support **post** and **get**

* **base_url**: Base url where requests will be made

* **body**: request body (optional)
* **headers**: For now we support authorization bearer token (optional)
* **config**:
  * **number_of_requests**: number of requests that quake needs to execute
  * **max_threads_number**: maximum number of threads that quake can create, for now the maximum is 30

## Graphql settings

For graphql requests the above settings can be applied, however, we have added more options that are essential for graphql requests

## Configuration file example (graphql)

```json
{
  "type": "Graphql",
  "method_http": "POST",
  "base_url": "https://example-api.com",
  "endpoint": "/graphql",
  "body": {
    "variables": {}
    },
  "headers": {
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9"
  },
  "config": {
    "number_of_requests": 10,
    "max_threads_number": 10
  }
}
```

In graphql configurations it is possible to use a parameter called variables, where we can add the graphql query variables.

Furthermore, it is mandatory to create a second file within the same directory called **query.graphql**, with the graphql query that will be executed in the test.

## Example Graphql Query File

```graphql
{
  accounts {
    nodes {
      id
      name
    }
  }
}
```
After creating your configuration file, simply run rake passing the file path of your .json file

## Example:

```bash
rake quake:start_service["./templates/example/load.json"]
```
