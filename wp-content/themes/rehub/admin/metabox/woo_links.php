<?php

return array(
	'id'          => 'rehub_framework_woo',
	'types'       => array('product'),
	'title'       => __('Additional Deals panel', 'rehub_framework'),
	'priority'    => 'low',
	'mode'        => WPALCHEMY_MODE_EXTRACT,
	'template'    => array(
		array(
			'type'      => 'textbox',
			'name'      => 'rehub_deals_title',
			'label'     => __('Title of deals widget', 'rehub_framework'),
			'description' => __('Insert title or leave blank', 'rehub_framework'),						
		),
		 array(
			'type' => 'notebox',
			'name' => 'rehub_woo_deal_note',
			'label' => __('Note!', 'rehub_framework'),
			'description' => __('You can show additional deals as woocommerce offers, thirstyaffiliate offers or any other data based on shortcode. Please, choose one of field below or leave blank this section. Read more in <a href="http://rehub.wpsoul.com/documentation/docs.html#31" target="_blank">documentation</a>', 'rehub_framework'),
			'status' => 'info',
		),		
		rehub_woo_select_two(),
		array(
			'type' => 'multiselect',
			'name' => 'review_woo_links',
			'label' => __('Choose affiliate offers', 'rehub_framework'),
			'description' => __('Choose affiliate links that you want to show in list.', 'rehub_framework'),
			'items' => array(
				'data' => array(
					array(
						'source' => 'function',
						'value'  => 'rehub_get_aff',
					),
				),
			),
			'default' => '',																																						
		),
		array(
			'type'      => 'textbox',
			'name'      => 'rehub_woodeals_short',
			'label'     => __('Shortcode for offers', 'rehub_framework'),						
		),		
		array(
			'type' => 'select',
			'name' => 'review_woo_id',
			'label' => __('Choose related review post', 'rehub_framework'),
			'description' => __('Choose post with review of this product', 'rehub_framework'),
			'items' => array(
				'data' => array(
					array(
						'source' => 'function',
						'value'  => 'rehub_manual_ids_func',
					),
				),
			),			
			'default' => '',
		),																						
	),
);

/**
 * EOF
 */