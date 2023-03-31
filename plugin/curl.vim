if exists('g:curl_vim_loaded')
	finish
endif
let g:curl_vim_loaded = 1

if !exists('g:curl_vim_bin')
	let g:curl_vim_bin = 'curl'
endif

if !exists('g:curl_vim_execute_type')
	let g:curl_vim_execute_type = 'system'
endif
