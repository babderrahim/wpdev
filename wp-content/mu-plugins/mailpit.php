<?php
/**
 * Plugin Name: Mailpit SMTP (dev only)
 * Description: Routes all wp_mail() through Mailpit. View mail at http://localhost:8025.
 */

add_action( 'phpmailer_init', function ( $phpmailer ) {
	$phpmailer->isSMTP();
	$phpmailer->Host     = 'mailpit';
	$phpmailer->Port     = 1025;
	$phpmailer->SMTPAuth = false;
	$phpmailer->SMTPAutoTLS = false;
} );

// WordPress builds the default sender from the site host, and PHPMailer rejects "wordpress@localhost".
add_filter( 'wp_mail_from', function ( $from ) {
	return str_ends_with( $from, '@localhost' ) ? 'wordpress@localhost.test' : $from;
} );
