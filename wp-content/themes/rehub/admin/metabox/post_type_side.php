<?php

return array(
	'id'          => 'rehub_post_side',
	'types'       => array('post'),
	'title'       => __('Post settings', 'rehub_framework'),
	'priority'    => 'low',
	'mode'        => WPALCHEMY_MODE_EXTRACT,
	'context'     => 'side',
	'template'    => array(

		array(
			'type' => 'textbox',
			'name' => 'read_more_custom',
			'label' => __('Read More custom text', 'rehub_framework'),
			'description' => __('Will be used in some blocks instead of default read more text', 'rehub_framework'),
			'default' => '',
		),		

		array(
			'type' => 'radiobutton',
			'name' => 'post_size',
			'label' => __('Post w/ sidebar or Full width', 'rehub_framework'),
			'description' => __('Note, normal post width - 765px, full width - 1130px', 'rehub_framework'),
			'default' => 'normal_post',
			'items' => array(
				array(
					'value' => 'normal_post',
					'label' => __('Post w/ Sidebar', 'rehub_framework'),
				),
				array(
					'value' => 'full_post',
					'label' => __('Full Width Post', 'rehub_framework'),
				)
			)
		),
		array(
			'type' => 'toggle',
			'name' => 'is_featured',
			'label' => __('Featured Post', 'rehub_framework'),
			'description' => __('Add this post to the featured posts section on homepage?', 'rehub_framework'),
		),

		array(
			'type' => 'radiobutton',
			'name' => 'filter_featured_for',
			'label' => __('Display in:', 'rehub_framework'),
			'items' => array(
				array(
					'value' => 'featured_for_slider',
					'label' => __('Display in slider', 'rehub_framework'),
				),
				array(
					'value' => 'featured_for_right',
					'label' => __('Display in right section', 'rehub_framework'),
				),
			),
			'default' => array(
				'featured_for_slider',
			),			
			'dependency' => array(
				'field' => 'is_featured',
				'function' => 'vp_dep_boolean',
		 	),
 		),

		rehub_custom_badge_admin(),

		array(
			'type' => 'toggle',
			'name' => 'show_featured_image',
			'label' => __('Disable Featured Image, Video or Gallery in top part on post page', 'rehub_framework'),
			'default' => '0',
		),		

		array(
			'type' => 'toggle',
			'name' => 'disable_parts',
			'label' => __('Disable parts?', 'rehub_framework'),
			'description' => __('Check this box if you want to disable tags, breadcrumbs, author box, share buttons in post', 'rehub_framework'),
		), 		

		array(
			'type' => 'toggle',
			'name' => 'show_banner_ads',
			'label' => __('Disable global ads after post', 'rehub_framework'),
			'description' => '',
			'default' => '0',
			'dependency' => array(
				'field' => 'disable_parts',
				'function' => 'vp_dep_boolean',
		 	),			
		),		
	),
);

/**
 * EOF
 */