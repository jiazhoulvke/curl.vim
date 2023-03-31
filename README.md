对 curl 命令的封装，方便在 vim 脚本中执行网络请求。

# API

目前提供如下接口：

- `curl_vim#request(method, url, data = {}, options = {})`
- `curl_vim#get(url, options = {})`
- `curl_vim#post_form(url, data = {}, options = {})`
- `curl_vim#post_multipart_form(url, data = {}, options = {})`
- `curl_vim#post_json(url, data = {}, options = {})`
- `curl_vim#patch(url, data = {}, options = {})`
- `curl_vim#put(url, data = {}, options = {})`
- `curl_vim#delete(url, data = {}, options = {})`
- `curl_vim#head(url, data = {}, options = {})`

最主要的接口是 `curl_vim#request()` ，其他接口的都是对 `curl_vim#request()` 的简单封装。

- `method` 为请求方式，如 GET、POST、DELETE等。
- `url` 是需要请求的地址。
- `data` 为需要发送的数据，可以是 string 或者 dict
- `options` 是 `curl` 参数。
  - 如果值为字符串，比如 `{'-H': 'user-agent: Mozilla/5.0'}`，相当于执行: 

    ```curl -s http://example.com -H "user-agent: Mozilla/5.0"```

  - 如果值为 `list`，比如 `{'-H': ['user-agent: Mozilla/5.0', 'Content-Type: application/json']}`，则相当于执行:

    ```curl -s http://example.com -H "user-agent: Mozilla/5.0" -H "Content-Type: application/json"```

返回值为 `dict` 格式，如 `{'code': 0, 'http_code': 200, 'msg': '', 'header': '', 'body': ''}`。

- `code` 为错误码，如果为 `0` 表示执行成功
- `http_code` 为 http 状态码，从 header 提取而来
- `msg` 为错误信息, 当 `code` 不为 `0` 是返回
- `header` 为返回的 header
- `body` 为返回的数据主体

## GET

`curl_vim#get(url, options = {})`

### 示例

```vim
let result = curl_vim#get('https://httpbin.org/get', {'-H': 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36'})
echo json_encode(result)
```
```json
{"http_code": "200", "code": 0, "header": "HTTP/1.1 200 OK\nDate: Fri, 31 Mar 2023 07:53:15 GMT\nContent-Type: application/json\nContent-Length: 355\nConnection: keep-alive\nServer: gunicorn/19.9.0\nAccess-Control-Allow-Origin: *\nAccess-Control-Allow-Credentials: true\n", "body": "{\n  \"args\": {}, \n  \"headers\": {\n    \"Accept\": \"*/*\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36\", \n    \"X-Amzn-Trace-Id\": \"Root=1-6426916a-090cae060f9f86a37a696e93\"\n  }, \n  \"origin\": \"1.2.3.4\", \n  \"url\": \"https://httpbin.org/get\"\n}"}
```

## POST

### x-www-form-urlencoded

`curl_vim#post_form(url, data = {}, options = {})`

以 `x-www-form-urlencoded` 形式发送数据，相当于 `curl` 中的 `-d`

#### 示例

```vim
let result = curl_vim#post_form('https://httpbin.org/post', 'name=john&age=3')
echo json_encode(result)
```
```json
{"http_code": "200", "code": 0, "header": "HTTP/1.1 200 OK\nDate: Fri, 31 Mar 2023 08:36:27 GMT\nContent-Type: application/json\nContent-Length: 445\nConnection: keep-alive\nServer: gunicorn/19.9.0\nAccess-Control-Allow-Origin: *\nAccess-Control-Allow-Credentials: true\n", "body": "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {}, \n  \"form\": {\n    \"age\": \"3\", \n    \"name\": \"john\"\n  }, \n  \"headers\": {\n    \"Accept\": \"*/*\", \n    \"Content-Length\": \"15\", \n    \"Content-Type\": \"application/x-www-form-urlencoded\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"curl/7.83.1\", \n    \"X-Amzn-Trace-Id\": \"Root=1-64269b8b-7fe9a2a121e6c7df719a0365\"\n  }, \n  \"json\": null, \n  \"origin\": \"1.2.3.4\", \n  \"url\": \"https://httpbin.org/post\"\n}"}
```

### multipart/form-data

`curl_vim#post_multipart_form(url, data = {}, options = {}`)

以 `multipart/form-data` 形式发送数据，相当于 `curl` 中的 `-F`

#### 示例

```vim
let result = curl_vim#post_multipart_form('https://httpbin.org/post', {'foo':'bar', 'file': '@D:/test.txt'})
echo json_encode(result)
```
```json
{"http_code": "200", "code": 0, "header": "HTTP/1.1 200 OK\nDate: Fri, 31 Mar 2023 08:37:03 GMT\nContent-Type: application/json\nContent-Length: 495\nConnection: keep-alive\nServer: gunicorn/19.9.0\nAccess-Control-Allow-Origin: *\nAccess-Control-Allow-Credentials: true\n", "body": "{\n  \"args\": {}, \n  \"data\": \"\", \n  \"files\": {\n    \"file\": \"hello, world!\"\n  }, \n  \"form\": {\n    \"foo\": \"bar\"\n  }, \n  \"headers\": {\n    \"Accept\": \"*/*\", \n    \"Content-Length\": \"294\", \n    \"Content-Type\": \"multipart/form-data; boundary=------------------------8e2f74eb5627a788\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"curl/7.83.1\", \n    \"X-Amzn-Trace-Id\": \"Root=1-64269baf-30a729f55b5c944373109762\"\n  }, \n  \"json\": null, \n  \"origin\": \"1.2.3.4\", \n  \"url\": \"https://httpbin.org/post\"\n}"}
```

### json

`curl_vim#post_json(url, data = {}, options = {})`

发送 `json` 格式数据

#### 示例

```vim
let result = curl_vim#post_json('https://httpbin.org/post', {'name': 'zhangsan', 'age': 99})
echo json_encode(result)
```
```json
{"http_code": "200", "code": 0, "header": "HTTP/2 200 \r\ndate: Fri, 31 Mar 2023 10:06:27 GMT\r\ncontent-type: application/json\r\ncontent-length: 466\r\nserver: gunicorn/19.9.0\r\naccess-control-allow-origin: *\r\naccess-control-allow-credentials: true\r\n\r", "body": "{\n  \"args\": {}, \n  \"data\": \"{\\\"age\\\": 99, \\\"name\\\": \\\"zhangsan\\\"}\", \n  \"files\": {}, \n  \"form\": {}, \n  \"headers\": {\n    \"Accept\": \"*/*\", \n    \"Content-Length\": \"31\", \n    \"Content-Type\": \"application/json\", \n    \"Host\": \"httpbin.org\", \n    \"User-Agent\": \"curl/7.85.0\", \n    \"X-Amzn-Trace-Id\": \"Root=1-6426b0a3-4d7ac1a65f7f61475239de20\"\n  }, \n  \"json\": {\n    \"age\": 99, \n    \"name\": \"zhangsan\"\n  }, \n  \"origin\": \"1.2.3.4\", \n  \"url\": \"https://httpbin.org/post\"\n}\n\n"}
```

# 配置

- `g:curl_vim_bin` 用于设置curl可执行文件的路径，默认值: `curl`

  Win10 已经内置了一个curl，linux、unix系统通常也都自带了curl，所以一般不需要设置。

- `g:curl_vim_execute_type` 用于设置执行curl命令的方式，支持 `system` 和 `job` 两种方式，默认为 `system`。

  - system

    用 vim 自带的 `system()` 函数执行，在 windows 下会有个难看的命令行窗口

  - job

    使用新版vim 和 neovim 才支持的 job 特性执行。需要同时安装另一个插件: <https://github.com/prabirshrestha/async.vim>，
	然后在配置中设置 `let g:curl_vim_execute_type = 'job'`
