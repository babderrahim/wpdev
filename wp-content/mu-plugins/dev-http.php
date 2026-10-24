<?php
/**
 * Plugin Name: Dev HTTP fixes
 * Description: api.wordpress.org rejects (HTTP 434) user agents containing "http://localhost:<port>",
 *              which breaks plugin/theme installs. Send the bare "WordPress/x.y" agent instead.
 */

add_filter( 'http_request_args', function ( $args, $url ) {
	if ( str_contains( $url, 'wordpress.org' ) ) {
		$args['user-agent'] = 'WordPress/' . get_bloginfo( 'version' );
	}
	return $args;
}, 10, 2 );
