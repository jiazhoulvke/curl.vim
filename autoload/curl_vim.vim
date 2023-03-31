function! s:on_stdout(jobid, data, event_type) abort
	if !has_key(s:execute_result, a:jobid)
		let s:execute_result[a:jobid] = []
	endif
	if type(a:data) == v:t_string
		let s:execute_result[a:jobid] = add(s:execute_result[a:jobid], a:data)
	elseif type(a:data) == v:t_list
		let s:execute_result[a:jobid] = extend(s:execute_result[a:jobid], a:data)
	endif
endfunction

function! curl_vim#execute(cmd) abort
	if g:curl_vim_execute_type == 'system'
		let result = split(system(a:cmd), "\n")
		if v:shell_error != 0
			return {'code': v:shell_error, 'msg': 'execute curl failed'}
		endif
		return {'code': 0, 'data': result}
	endif
	if !exists('s:execute_result')
		let s:execute_result = {}
	endif
	let jobid = async#job#start(a:cmd, { 'on_stdout': function('s:on_stdout') })
	if jobid <= 0
		return {'code': -1, 'msg': 'job failed to start'}
	endif
	call async#job#wait([jobid], -1)
	let data = s:execute_result[jobid]
	call remove(s:execute_result, jobid)
	return {'code': 0, 'data': data}
endfunction

function! curl_vim#find_curl_options(options, key, pat) abort
	let keys = []
	if type(a:key) == v:t_string
		let keys = [a:key]
	else
		let keys = a:key
	endif
	let result = []
	for key in keys
		let values = []
		if has_key(a:options, key)
			let value = a:options[key]
			if type(value) == v:t_string
				let values = [value]
			else
				let values = value
			endif
			for item in values
				if match(item, a:pat) > -1
					let result = add(result, item)
				endif
			endfor
		endif
	endfor
	return result
endfunction

function! curl_vim#append_curl_options(options, key, value) abort
	let options = copy(a:options)
	if has_key(options, a:key)
		if type(options[a:key]) == v:t_string
			let new_header = [options[a:key], a:value]
			let options[a:key] = new_header
		else
			let new_header = add(options[a:key], a:value)
			let options[a:key] = new_header
		endif
	else
		let options[a:key] = a:value
	endif
	return options
endfunction

function! curl_vim#request(method, url, data = {}, options = {}) abort
	if !executable(g:curl_vim_bin)
		return {'code': -1, 'msg': g:curl_vim_bin.' is not executable'}
	endif
	let cmd = '"'.g:curl_vim_bin.'" -i -s -X '.a:method.' "'.a:url.'"'
	for [k, v] in items(a:options)
		if type(v) == v:t_list
			for item in v
				let cmd = cmd.' '.k.' "'.item.'"'
			endfor
		else
			let cmd = cmd.' '.k.' "'.v.'"'
		endif
	endfor
	let tmp = ''
	if len(a:data) > 0
		let content_type = ''
		let content_types = curl_vim#find_curl_options(a:options, ['-H', '--header'], '^Content-Type:')
		if len(content_types) > 0
			let content_type = content_types[0]
			if match(content_type, 'form') > -1
				let data_type = 'form'
			endif
		endif
		let data_type = 'raw'
		if match(content_type, 'form') > -1
			let data_type = 'form'
		endif
		if data_type == 'form'
			let p = '-d'
			if match(content_type, 'multipart/form-data') > -1
				let p = '-F'
			endif
			if type(a:data) == v:t_string
				let cmd = cmd.' '.p.' "'.a:data.'"'
			else
				for [k, v] in items(a:data)
					let cmd = cmd. ' '.p.' "'.k.'='.v.'"'
				endfor
			endif
		else
			let data = a:data
			if type(a:data) == v:t_dict || type(a:data) == v:t_list
				let data = json_encode(a:data)
			endif
			let tmp = tempname()
			if writefile([json_encode(data)], tmp, "b") == -1
				return {'code': -1, 'msg': 'write data to temporary file failed'}
			endif
			let cmd = cmd .' -d "@'.tmp.'"'
		endif
	endif
	let result = curl_vim#execute(cmd)
	if tmp != ''
		call delete(tmp)
	endif
	if result['code'] != 0
		return {'code': result['code'], 'msg': result['msg']}
	endif
	let data = result['data']
	if len(data) == 0
		return {'code': 0, 'header': '', 'body': ''}
	endif
	if match(data[0], '^HTTP/\d') == -1
		return {'code': 0, 'header': '', 'body': join(data, "\n")}
	endif
	let n = 0
	let blank_line_num = -1
	for line in data
		if trim(line) == ''
			let blank_line_num = n
			break
		endif
		let n = n + 1
	endfor
	if blank_line_num > -1
		let header = join(data[:blank_line_num], "\n")
		if len(data)-blank_line_num > 1
			let body = join(data[blank_line_num+1:], "\n")
		else
			let body = ''
		endif
	else
		let header = join(result['header'], "\n")
		let body = ''
	endif
	let result = {'code': 0, 'header': header, 'body': body}
	let http_code_p= match(data[0], ' \d\d\d ')
	if http_code_p > -1
		let result['http_code'] = strpart(data[0], http_code_p+1, 3)
	endif
	return result
endfunction

function! curl_vim#get(url, options = {}) abort
	return curl_vim#request('GET', a:url, {}, a:options)
endfunction

function! curl_vim#post_form(url, data = {}, options = {})
	let options = curl_vim#append_curl_options(a:options, '-H', 'Content-Type: application/x-www-form-urlencoded')
	return curl_vim#request('POST', a:url, a:data, options)
endfunction

function! curl_vim#post_multipart_form(url, data = {}, options = {})
	let options = curl_vim#append_curl_options(a:options, '-H', 'Content-Type: multipart/form-data')
	return curl_vim#request('POST', a:url, a:data, options)
endfunction

function! curl_vim#post_json(url, data = {}, options = {})
	let options = curl_vim#append_curl_options(a:options, '-H', 'Content-Type: application/json')
	return curl_vim#request('POST', a:url, a:data, options)
endfunction

function! curl_vim#patch(url, data = {}, options = {})
	return curl_vim#request('PATCH', a:url, a:data, a:options)
endfunction

function! curl_vim#put(url, data = {}, options = {})
	return curl_vim#request('PUT', a:url, a:data, a:options)
endfunction

function! curl_vim#delete(url, data = {}, options = {})
	return curl_vim#request('DELETE', a:url, a:data, a:options)
endfunction

function! curl_vim#head(url, data = {}, options = {})
	return curl_vim#request('HEAD', a:url, a:data, a:options)
endfunction
