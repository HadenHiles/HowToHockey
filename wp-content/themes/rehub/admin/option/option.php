<?php
$imagedir = get_template_directory_uri().'/images/';
return array(
	'title' => __('Theme Options', 'rehub_framework'),
	'page' => 'Rehub Theme Options',
	'logo' => '',
	'menus' => array(
		array(
			'title' => __('General Options', 'rehub_framework'),
			'name' => 'menu_1',
			'icon' => 'font-awesome:fa-codepen',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('General Options', 'rehub_framework'),
					'fields' => array(
					
						array(
							'type' => 'select',
							'name' => 'rehub_framework_archive_layout',
							'label' => __('Select Blog Layout', 'rehub_framework'),
							'description' => __('Select what kind of post string layout you want to use for blog, archives', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'rehub_framework_archive_blog',
									'label' => __('Blog Layout', 'rehub_framework'),
								),								
								array(
									'value' => 'rehub_framework_archive_list',
									'label' => __('List Layout with left thumbnails', 'rehub_framework'),
								),	
								array(
									'value' => 'rehub_framework_archive_grid',
									'label' => __('Grid layout', 'rehub_framework'),
								),
								array(
									'value' => 'rehub_framework_archive_gridfull',
									'label' => __('Full width Grid layout', 'rehub_framework'),
								),																							
							),
							'default' => array(
								'rehub_framework_archive_list',
							),
						),
						array(
							'type' => 'select',
							'name' => 'rehub_framework_category_layout',
							'label' => __('Select Category Layout', 'rehub_framework'),
							'description' => __('Select what kind of post string layout you want to use for categories', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'rehub_framework_category_blog',
									'label' => __('Blog Layout', 'rehub_framework'),
								),								
								array(
									'value' => 'rehub_framework_category_list',
									'label' => __('List Layout with left thumbnails', 'rehub_framework'),
								),
								array(
									'value' => 'rehub_framework_category_grid',
									'label' => __('Grid layout with sidebar', 'rehub_framework'),
								),	
								array(
									'value' => 'rehub_framework_category_gridfull',
									'label' => __('Full width Grid layout', 'rehub_framework'),
								),																									
							),
							'default' => array(
								'rehub_framework_category_list',
							),
						),
						array(
							'type' => 'select',
							'name' => 'rehub_framework_search_layout',
							'label' => __('Select Search Layout', 'rehub_framework'),
							'description' => __('Select what kind of post string layout you want to use for search pages', 'rehub_framework'),
							'items' => array(							
								array(
									'value' => 'rehub_framework_archive_list',
									'label' => __('List Layout with left thumbnails', 'rehub_framework'),
								),	
								array(
									'value' => 'rehub_framework_archive_grid',
									'label' => __('Grid layout', 'rehub_framework'),
								),
								array(
									'value' => 'rehub_framework_archive_gridfull',
									'label' => __('Full width Grid layout', 'rehub_framework'),
								),																							
							),
							'default' => array(
								'rehub_framework_archive_list',
							),
						),							
											
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_custom_css',
							'label' => __('Custom CSS', 'rehub_framework'),
							'description' => __('Write your custom CSS here', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'css',
						),						
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_analytics',
							'label' => __('Analytics Code/js code', 'rehub_framework'),
							'description' => __('Enter your Analytics code or any html, js code', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_sidebar_left',
							'label' => __('Set sidebar to left side?', 'rehub_framework'),
							'default' => '0',
						),																			
					),
				),
			),
		),
		array(
			'title' => __('Logo & favicon', 'rehub_framework'),
			'name' => 'menu_12',
			'icon' => 'font-awesome:fa-gear',
			'controls' => array(

				array(
					'type' => 'section',
					'title' => __('Logo settings', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'upload',
							'name' => 'rehub_logo',
							'label' => __('Upload Logo', 'rehub_framework'),
							'description' => __('Upload your logo. Max width is 463px. (1200px for full width)', 'rehub_framework'),
							'default' => '',
						),
						 array(
							'type' => 'slider',
							'name' => 'rehub_logo_margin',
							'label' => __('Margin logo from top', 'rehub_framework'),
							'description' => __('Set space between logo and top area in pixels', 'rehub_framework'),
							'min' => '0',
							'max' => '100',
							'step' => '5',
							'default' => '5',
						),						
						array(
							'type' => 'upload',
							'name' => 'rehub_logo_retina',
							'label' => __('Upload Logo (retina version)', 'rehub_framework'),
							'description' => __('Upload retina version of the logo. It should be 2x the size of main logo.', 'rehub_framework'),
							'default' => '',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_logo_retina_width',
							'label' => __('Retina logo width', 'rehub_framework'),
							'description' => __('If retina logo is uploaded, please enter the standard logo (1x) version width, do not enter the retina logo width.', 'rehub_framework'),
						),	
						array(
							'type' => 'textbox',
							'name' => 'rehub_logo_retina_height',
							'label' => __('Retina logo height', 'rehub_framework'),							
							'description' => __('If retina logo is uploaded, please enter the standard logo (1x) version height, do not enter the retina logo height.', 'rehub_framework'),
						),																	
						array(
							'type' => 'textbox',
							'name' => 'rehub_text_logo',
							'label' => __('Text logo', 'rehub_framework'),							
							'description' => __('You can type text logo. Use this field only if no image logo', 'rehub_framework'),
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_text_slogan',
							'label' => __('Slogan', 'rehub_framework'),							
							'description' => __('You can type slogan below text logo. Use this field only if no image logo', 'rehub_framework'),
						),							
					),
				),

				array(
					'type' => 'section',
					'title' => __('Favicons', 'rehub_framework'),
					'fields' => array(
						 array(
							'type' => 'notebox',
							'name' => 'rehub_favicon_note',
							'label' => __('Note!', 'rehub_framework'),
							'description' => __('Wordpress 4.3 has built-in favicon function. You can set favicon from Appearance - Customize - Site Identity - Site Icon', 'rehub_framework'),
							'status' => 'info',
						),						
					),
				),
			),
		),
		array(
			'title' => __('Header and Menu', 'rehub_framework'),
			'name' => 'menu_2',
			'icon' => 'font-awesome:fa-wrench ',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Main Header Options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'rehub_header_style',
							'label' => __('Select Header style', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'header_first',
									'label' => __('Logo + code zone 468X60 + search box', 'rehub_framework'),
								),
								array(
									'value' => 'header_second',
									'label' => __('Logo + code zone 728X90', 'rehub_framework'),
								),
								array(
									'value' => 'header_third',
									'label' => __('Full width logo', 'rehub_framework'),
								),
								array(
									'value' => 'header_fourth',
									'label' => __('Full width logo + full width code zone', 'rehub_framework'),
								),	
								array(
									'value' => 'header_five',
									'label' => __('Logo + menu', 'rehub_framework'),
								),															
							),
								'default' => array(
								'header_first',
							),
						),	
						array(
							'type' => 'select',
							'name' => 'rehub_search_icon',
							'label' => __('Add additional search icon', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'no',
									'label' => __('No additional icon', 'rehub_framework'),
								),
								array(
									'value' => 'top',
									'label' => __('In top line', 'rehub_framework'),
								),
								array(
									'value' => 'menu',
									'label' => __('In main menu', 'rehub_framework'),
								),															
							),
								'default' => array(
								'top',
							),
						),											
						array(
							'type' => 'toggle',
							'name' => 'rehub_body_block',
							'label' => __('Enable block width of header', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'toggle',
							'name' => 'rehub_sticky_nav',
							'label' => __('Sticky Navigation Bar', 'rehub_framework'),
							'description' => __('Enable/Disable Sticky navigation bar.', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'select',
							'name' => 'header_logoline_style',
							'label' => __('Choose color style of header logo section', 'rehub_framework'),							
							'items' => array(
								array(
									'value' => '0',
									'label' => __('White style and dark fonts', 'rehub_framework'),
								),
								array(
									'value' => '1',
									'label' => __('Dark style and white fonts', 'rehub_framework'),
								),
							),
							'default' => array(
								'0',
							),
						),
						array(
							'type' => 'color',
							'name' => 'rehub_header_color_background',
							'label' => __('Custom Background Color', 'rehub_framework'),
							'description' => __('Choose the background color or leave blank for default', 'rehub_framework'),
							'format' => 'hex',	
						),
						array(
							'type' => 'upload',
							'name' => 'rehub_header_background_image',
							'label' => __('Custom Background Image', 'rehub_framework'),
							'description' => __('Upload a background image or leave blank', 'rehub_framework'),
							'default' => '',
							
						),
						array(
							'type' => 'select',
							'name' => 'rehub_header_background_repeat',
							'label' => __('Background Repeat', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'repeat',
									'label' => __('Repeat', 'rehub_framework'),
								),
								array(
									'value' => 'no-repeat',
									'label' => __('No Repeat', 'rehub_framework'),
								),
								array(
									'value' => 'repeat-x',
									'label' => __('Repeat X', 'rehub_framework'),
								),
								array(
									'value' => 'repeat-y',
									'label' => __('Repeat Y', 'rehub_framework'),
								),
							),
							
						),
						array(
							'type' => 'select',
							'name' => 'rehub_header_background_position',
							'label' => __('Background Position', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'left',
									'label' => 'Left',
								),
								array(
									'value' => 'center',
									'label' => 'Center',
								),
								array(
									'value' => 'right',
									'label' => 'Right',
								),
							),													
						),																										
					),
				),

				array(
					'type' => 'section',
					'title' => __('Header top line Options', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'header_topline_style',
							'label' => __('Choose color style of header top line', 'rehub_framework'),							
							'items' => array(
								array(
									'value' => '0',
									'label' => __('White style and dark fonts', 'rehub_framework'),
								),
								array(
									'value' => '1',
									'label' => __('Dark style and white fonts', 'rehub_framework'),
								),
							),
							'default' => array(
								'0',
							),
						),
						 array(
							'type' => 'color',
							'name' => 'rehub_custom_color_top',
							'label' => __('Custom color for top line of header', 'rehub_framework'),
							'description' => __('Or leave blank for default color', 'rehub_framework'),
							'format' => 'hex',
							
						),	
						 array(
							'type' => 'color',
							'name' => 'rehub_custom_color_top_font',
							'label' => __('Custom color of menu font for top line of header', 'rehub_framework'),
							'description' => __('Or leave blank for default color', 'rehub_framework'),
							'format' => 'hex',				
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_header_social',
							'label' => __('Enable Header Social Icons', 'rehub_framework'),
							'description' => __('You can set your social media URLs in the Social Media Options tab.', 'rehub_framework'),
							'default' => '1',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_logged_enable_intop',
							'label' => __('Replace top menu when user logined', 'rehub_framework'),
							'description' => __('Default top menu will be replaced with /User Logged In Menu/', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'toggle',
							'name' => 'exclude_cart_header',
							'label' => __('Disable cart in header', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'toggle',
							'name' => 'rehub_header_top',
							'label' => __('Disable top line', 'rehub_framework'),
							'description' => __('You can disable top line', 'rehub_framework'),
							'default' => '0',
						),									
		
					),
				),

				array(
					'type' => 'section',
					'title' => __('Header main menu Options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'header_menuline_style',
							'label' => __('Choose color style of header menu section', 'rehub_framework'),							
							'items' => array(
								array(
									'value' => '0',
									'label' => __('White style and dark fonts', 'rehub_framework'),
								),
								array(
									'value' => '1',
									'label' => __('Dark style and white fonts', 'rehub_framework'),
								),
							),
							'default' => array(
								'1',
							),
						),
						array(
							'type' => 'color',
							'name' => 'rehub_custom_color_nav',
							'label' => __('Custom color of menu background', 'rehub_framework'),
							'description' => __('Or leave blank for default color', 'rehub_framework'),
							'format' => 'hex',
							
						),	
						 array(
							'type' => 'color',
							'name' => 'rehub_custom_color_nav_font',
							'label' => __('Custom color of menu font', 'rehub_framework'),
							'description' => __('Or leave blank for default color', 'rehub_framework'),
							'format' => 'hex',							
						),
					),
				),

				array(
					'type' => 'section',
					'title' => __('News ticker', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_enable_newstick',
							'label' => __('Enable news ticker', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_enable_newstick_home',
							'label' => __('Show only on home', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'textbox',
							'name' => 'rehub_newstick_label',
							'label' => __('Type label of newsticker', 'rehub_framework'),
							'default' => 'Special',							
						),						
						array(
							'type' => 'multiselect',
							'name' => 'rehub_newstick_cat',
							'label' => __('Categories', 'rehub_framework'),
							'description' => __('Pick the categories that will show in Newsticker.', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_categories',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_newstick_tag',
							'label' => __('Tags', 'rehub_framework'),
							'description' => __('Pick the tags that will show in Newsticker.', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_tags',
									),
								),
							),						
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_newstick_fetch',
							'label' => __('Number of posts to display', 'rehub_framework'),
							'default' => '5',
							'validation' => 'numeric',							
						),						

					),
				),							
			),
		),
		array(
			'title' => __('Footer Options', 'rehub_framework'),
			'name' => 'menu_3',
			'icon' => 'font-awesome:fa-caret-square-o-down',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Footer options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_footer_widgets',
							'label' => __('Footer Widgets', 'rehub_framework'),
							'description' => __('Enable or Disable the footer widget area', 'rehub_framework'),
							'default' => '1',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_footer_block',
							'label' => __('Enable footer block width?', 'rehub_framework'),
							'default' => '0',
						),						
					
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_footer_text',
							'label' => __('Footer Bottom Text', 'rehub_framework'),
							'description' => __('Enter your copyright text or whatever you want right here.', 'rehub_framework'),
							'default' => '&copy; 2014 Sizam Design. All rights reserved.',
							'theme' => 'chrome',
							'mode' => 'html',
						),
						array(
							'type' => 'upload',
							'name' => 'rehub_footer_logo',
							'label' => __('Upload Logo for footer', 'rehub_framework'),
							'description' => __('Upload your logo for footer.', 'rehub_framework'),
							'default' => '',
						),						
					),
				),
			),
		),
		array(
			'title' => __('Homepage Options', 'rehub_framework'),
			'name' => 'menu_4',
			'icon' => 'font-awesome:fa-home',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Featured Area Options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_featured_toggle',
							'label' => __('Display Featured Area', 'rehub_framework'),
							'description' => __('Display the featured area on the homepage', 'rehub_framework'),
							'default' => '0',
						),	

						array(
							'type' => 'notebox',
							'name' => 'rehub_featured_note',
							'label' => __('Note', 'rehub_framework'),
							'description' => __('Each post has option to be chosen as Featured Post in post settings. You need to have minimum 5 featured posts (3 for slider and 2 for right section) for correct work of feature section. Also, you can create featured section based on tag name. Don\'t choose any posts and set tag for this. If you leave all fields blank, 5 last posts that you mark as featured will be shown', 'rehub_framework'),
							'status' => 'normal',
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),																


						array(
							'type' => 'sorter',
							'max_selection' => 6,
							'name' => 'rehub_featured_slider',
							'label' => __('Posts for feature slider', 'rehub_framework'),
							'description' => __('Select posts for feature slider', 'rehub_framework'),
							'items'=> array(
								'data' => array(
									array(
										'source' => 'function',
										'value'  => 'rehub_framework_get_featured_posts'
									)
								)
							),
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),
						),						

						array(
							'type' => 'sorter',
							'max_selection' => 2,
							'name' => 'rehub_featured_right',
							'label' => __('Posts for right feature section', 'rehub_framework'),
							'description' => __('Select 2 posts for right feature section', 'rehub_framework'),
							'items'=> array(
								'data' => array(
									array(
										'source' => 'function',
										'value'  => 'rehub_framework_get_featured_posts_right'
									)
								)
							),
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),
						),
						array(
							'type' => 'color',
							'name' => 'rehub_feature_color',
							'label' => __('Set color for overlay in slider', 'rehub_framework'),
							'description' => __('Or leave blank for slider without overlay', 'rehub_framework'),
							'format' => 'rgba',
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							  
						),													


						array(
							'type' => 'textbox',
							'name' => 'rehub_featured_tag',
							'label' => __('Set tag', 'rehub_framework'),
							'description' => __('Set slug of tag', 'rehub_framework'),
							'default' => '',
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),											

						array(
							'type' => 'toggle',
							'name' => 'rehub_exclude_posts',
							'label' => __('Exclude featured posts from posts string', 'rehub_framework'),
							'description' => __('Set this to on if you want to exclude your featured posts from posts string of other post blocks', 'rehub_framework'),
							'default' => '0',
							'dependency' => array(
                            	'field' => 'rehub_featured_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),
					),
				),

				array(
					'type' => 'section',
					'title' => __('Home page carousel Options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_homecarousel_toggle',
							'label' => __('Display Homepage carousel', 'rehub_framework'),
							'description' => __('Display fullwidth carousel area on the homepage', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_homecarousel_ed',
							'label' => __('Editor\'s choice posts', 'rehub_framework'),
							'description' => __('Display posts with editor\'s choice label?', 'rehub_framework'),
							'default' => '0',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),																	
						array(
							'type' => 'textbox',
							'name' => 'rehub_homecarousel_tag',
							'label' => __('Or from tag', 'rehub_framework'),
							'description' => __('Or enter name of tag for posts to show (also disable checkbox above for this)', 'rehub_framework'),
							'default' => '',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),
						array(
							'type' => 'notebox',
							'name' => 'rehub_homecarousel_note',
							'label' => __('Note', 'rehub_framework'),
							'description' => __('You need to have minimum 5 posts for correct work of feature section. Editor\'s choice label you can set in options of each post on right section.', 'rehub_framework'),
							'status' => 'normal',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_homecarousel_label',
							'label' => __('Show badge on carousel', 'rehub_framework'),
							'description' => __('Display badge on carousel?', 'rehub_framework'),
							'default' => '1',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),
						array(
							'type' => 'select',
							'name' => 'rehub_label_color',
							'label' => __('Choose badge color', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'def',
								'label' => __('Orange - default', 'rehub_framework'),
								),
								array(
								'value' => 'blue',
								'label' => __('Blue', 'rehub_framework'),
								),
								array(
								'value' => 'green',
								'label' => __('Green', 'rehub_framework'),
								),
								array(
								'value' => 'violet',
								'label' => __('Violet', 'rehub_framework'),
								),								
								),
							'default' => 'def',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),								
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_homecarousel_label_text',
							'label' => __('Set text on label', 'rehub_framework'),
							'description' => __('Text in span tag will be on second row, please, use short text (8 symbols for 1 row, 7 symbols for 2 row)', 'rehub_framework'),
							'default' => 'Editor\'s <span>choice</span>',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),		
						array(
							'type' => 'toggle',
							'name' => 'rehub_homecarousel_cat',
							'label' => __('Display on category pages?', 'rehub_framework'),
							'description' => __('Display fullwidth carousel area also on category pages?', 'rehub_framework'),
							'default' => '0',
							'dependency' => array(
                            	'field' => 'rehub_homecarousel_toggle',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),																
					),
				),


			),
		),
		array(
			'title' => __('Social Media Options', 'rehub_framework'),
			'name' => 'menu_5',
			'icon' => 'font-awesome:fa-twitter',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Social Media Pages', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'textbox',
							'name' => 'rehub_facebook',
							'label' => __('Facebook link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_twitter',
							'label' => __('Twitter link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_google',
							'label' => __('Google plus link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_instagram',
							'label' => __('Instagram link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_tumblr',
							'label' => __('Tumblr link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_youtube',
							'label' => __('Youtube link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_vimeo',
							'label' => __('Vimeo link', 'rehub_framework'),
							'validation' => 'url',
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_pinterest',
							'label' => __('Pinterest link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_linkedin',
							'label' => __('Linkedin link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_soundcloud',
							'label' => __('Soundcloud link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_dribbble',
							'label' => __('Dribbble link', 'rehub_framework'),
							'validation' => 'url',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_vk',
							'label' => __('Vk.com link', 'rehub_framework'),
							'validation' => 'url',
						),

						array(
							'type' => 'textbox',
							'name' => 'rehub_rss',
							'label' => __('Rss link', 'rehub_framework'),
							'validation' => 'url',
						),												
					),
				),
			),
		),
		array(
			'title' => __('Appearance/Color', 'rehub_framework'),
			'name' => 'menu_6',
			'icon' => 'font-awesome:fa-pencil-square-o',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Color schema of website', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'rehub_color_schema',
							'label' => __('Choose color schema', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'default',
									'label' => __('Default - orange', 'rehub_framework'),
								),
								array(
									'value' => 'blue',
									'label' => __('Blue', 'rehub_framework'),
								),
								array(
									'value' => 'green',
									'label' => __('Green', 'rehub_framework'),
								),
								array(
									'value' => 'violet',
									'label' => __('Violet', 'rehub_framework'),
								),
								array(
									'value' => 'yellow',
									'label' => __('Yellow', 'rehub_framework'),
								),								
							),
							'default' => array(
								'default',
							),
						),
						array(
							'type' => 'color',
							'name' => 'rehub_custom_color',
							'label' => __('Custom color', 'rehub_framework'),
							'description' => __('Or you can set any main color (it will be used under white text)', 'rehub_framework'),
							'format' => 'hex',
						),
						array(
							'type' => 'color',
							'name' => 'rehub_btnoffer_color',
							'label' => __('Set offer buttons color. Or button will use main color', 'rehub_framework'),
							'format' => 'hex',						
						),	
						array(
							'type' => 'color',
							'name' => 'rehub_color_link',
							'label' => __('Custom color for links inside posts', 'rehub_framework'),
							'format' => 'hex',	
						),											
					),
				),
				array(
					'type' => 'section',
					'title' => __('Background settings', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'color',
							'name' => 'rehub_bg_flat_color',
							'label' => __('Create flat color for background', 'rehub_framework'),
							'description' => __('This will disable default background image and add flat color. If you want to add background image, use fields below', 'rehub_framework'),
							'format' => 'hex',
						),						
						array(
							'type' => 'color',
							'name' => 'rehub_color_background',
							'label' => __('Background Color', 'rehub_framework'),
							'description' => __('Choose the background color', 'rehub_framework'),
							'format' => 'hex',
						),
						array(
							'type' => 'upload',
							'name' => 'rehub_background_image',
							'label' => __('Background Image', 'rehub_framework'),
							'description' => __('Upload a background image', 'rehub_framework'),
							'default' => '',
						),
						array(
							'type' => 'select',
							'name' => 'rehub_background_repeat',
							'label' => __('Background Repeat', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'repeat',
									'label' => __('Repeat', 'rehub_framework'),
								),
								array(
									'value' => 'no-repeat',
									'label' => __('No Repeat', 'rehub_framework'),
								),
								array(
									'value' => 'repeat-x',
									'label' => __('Repeat X', 'rehub_framework'),
								),
								array(
									'value' => 'repeat-y',
									'label' => __('Repeat Y', 'rehub_framework'),
								),
							),
							'default' => array(
								'repeat',
							),
						),
						array(
							'type' => 'select',
							'name' => 'rehub_background_position',
							'label' => __('Background Position', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'left',
									'label' => 'Left',
								),
								array(
									'value' => 'center',
									'label' => 'Center',
								),
								array(
									'value' => 'right',
									'label' => 'Right',
								),
							),
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_background_offset',
							'label' => __('Set offset', 'rehub_framework'),
							'description' => __('Set offset from top for background (without px) for avoid header overlap', 'rehub_framework'),
							'validation' => 'numeric',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_background_fixed',
							'label' => __('Fixed Background Image?', 'rehub_framework'),
							'description' => __('The background is fixed with regard to the viewport.', 'rehub_framework'),
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_sized_background',
							'label' => __('Fit size?', 'rehub_framework'),
							'description' => __('Set background image width and height to fit the size of window', 'rehub_framework'),
						),												
						array(
								'type' => 'toggle',
								'name' => 'rehub_content_shadow',
								'label' => __('Disable box shadow under content box?', 'rehub_framework'),
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_branded_bg_url',
							'label' => __('Url for branded background', 'rehub_framework'),
							'description' => __('Insert url that will be display on background', 'rehub_framework'),
							'default' => '',
							'validation' => 'url',
						),																			
					),
				),				
			),
		),
		array(
			'title' => __('Fonts Options', 'rehub_framework'),
			'name' => 'menu_7',
			'icon' => 'font-awesome:fa-font',
			'controls' => array(

				array(
					'type' => 'section',
					'title' => __('Navigation Font', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'rehub_nav_font',
							'label' => __('Navigation Font Family', 'rehub_framework'),
							'description' => __('Font for navigation', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_gwf_family',
									),
								),
							),
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_nav_font_style',
							'label' => __('Font Style', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_nav_font',
										'value' => 'vp_get_gwf_style',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_nav_font_weight',
							'label' => __('Font Weight', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_nav_font',
										'value' => 'vp_get_gwf_weight',
									),
								),
							),
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_nav_font_subset',
							'label' => __('Font Subset', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_nav_font',
										'value' => 'vp_get_gwf_subset',
									),
								),
							),
							'default' => 'latin',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_nav_font_trans',
							'label' => __('Disable uppercase?', 'rehub_framework'),
							'default' => '0',							
						),												
					),
				),//END NAV FONT

				array(
					'type' => 'section',
					'title' => __('Headings Font', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'rehub_headings_font',
							'label' => __('Headings Font Family', 'rehub_framework'),
							'description' => __('Font for headings in text, sidebar, footer', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_gwf_family',
									),
								),
							),
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_headings_font_style',
							'label' => __('Font Style', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_headings_font',
										'value' => 'vp_get_gwf_style',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_headings_font_weight',
							'label' => __('Font Weight', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_headings_font',
										'value' => 'vp_get_gwf_weight',
									),
								),
							),
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_headings_font_subset',
							'label' => __('Font Subset', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_headings_font',
										'value' => 'vp_get_gwf_subset',
									),
								),
							),
							'default' => 'latin',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_headings_font_trans',
							'label' => __('Disable uppercase?', 'rehub_framework'),
							'default' => '0',							
						),												
					),
				),//END Headings FONT

				array(
					'type' => 'section',
					'title' => __('Block Titles', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'rehub_block_font',
							'label' => __('Block Titles Font', 'rehub_framework'),
							'description' => __('Font for titles of content blocks and pages', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_gwf_family',
									),
								),
							),
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_block_font_style',
							'label' => __('Font Style', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_block_font',
										'value' => 'vp_get_gwf_style',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_block_font_weight',
							'label' => __('Font Weight', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_block_font',
										'value' => 'vp_get_gwf_weight',
									),
								),
							),
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_block_font_subset',
							'label' => __('Font Subset', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_block_font',
										'value' => 'vp_get_gwf_subset',
									),
								),
							),
							'default' => 'latin',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_block_font_trans',
							'label' => __('Disable uppercase?', 'rehub_framework'),
							'default' => '0',							
						),												
					),
				),//END Block titles FONT

				array(
					'type' => 'section',
					'title' => __('Slider Headings', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'rehub_slider_font',
							'label' => __('Slider Headings Font', 'rehub_framework'),
							'description' => __('Font for slider headings', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_gwf_family',
									),
								),
							),
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_slider_font_style',
							'label' => __('Font Style', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_slider_font',
										'value' => 'vp_get_gwf_style',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_slider_font_weight',
							'label' => __('Font Weight', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_slider_font',
										'value' => 'vp_get_gwf_weight',
									),
								),
							),
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_slider_font_subset',
							'label' => __('Font Subset', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_slider_font',
										'value' => 'vp_get_gwf_subset',
									),
								),
							),
							'default' => 'latin',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_slider_font_trans',
							'label' => __('Disable uppercase?', 'rehub_framework'),
							'default' => '0',							
						),													
					),
				),//END Slider FONT

				array(
					'type' => 'section',
					'title' => __('Body Font', 'rehub_framework'),
					'fields' => array(						
						array(
							'type' => 'select',
							'name' => 'rehub_body_font',
							'label' => __('Body Font Family', 'rehub_framework'),
							'description' => __('Font for body text', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_gwf_family',
									),
								),
							),
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_body_font_style',
							'label' => __('Font Style', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_body_font',
										'value' => 'vp_get_gwf_style',
									),
								),
							),
							'default' => array(
								'{{first}}',
							),							
						),
						array(
							'type' => 'radiobutton',
							'name' => 'rehub_body_font_weight',
							'label' => __('Font Weight', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_body_font',
										'value' => 'vp_get_gwf_weight',
									),
								),
							),
						),
						array(
							'type' => 'multiselect',
							'name' => 'rehub_body_font_subset',
							'label' => __('Font Subset', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'binding',
										'field' => 'rehub_body_font',
										'value' => 'vp_get_gwf_subset',
									),
								),
							),
							'default' => 'latin',
						),	
						array(
							'type' => 'textbox',
							'name' => 'body_font_size',
							'label' => __('Set body font size', 'rehub_framework'),
							'description' => __('Set font size in px', 'rehub_framework'),
						),											
					),
				),//END Body FONT


			),
		),
		array(
			'title' => __('Global Enable/Disable', 'rehub_framework'),
			'name' => 'menu_8',
			'icon' => 'font-awesome:fa-globe',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Global options', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'aq_resize',
							'label' => __('Enable resizer script', 'rehub_framework'),
							'description' => __('Use resizer script for thumbnails', 'rehub_framework'),
							'default' => '1',
						),
						array(
							'type' => 'toggle',
							'name' => 'aq_resize_crop',
							'label' => __('Disable crop in resizer script', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'toggle',
							'name' => 'shortcode_enable',
							'label' => __('Enable theme shortcode', 'rehub_framework'),
							'description' => __('Enable built-in shortcode plugin', 'rehub_framework'),
							'default' => '1',
						),	
						array(
							'type' => 'toggle',
							'name' => 'repick_social_disable',
							'label' => __('Disable social buttons on images', 'rehub_framework'),
							'description' => __('Enable/Disable buttons in grid loop', 'rehub_framework'),
							'default' => '0',
						),											
						array(
							'type' => 'toggle',
							'name' => 'exclude_author_meta',
							'label' => __('Disable author link', 'rehub_framework'),
							'description' => __('Disable author link from meta in string', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'exclude_cat_meta',
							'label' => __('Disable category link', 'rehub_framework'),
							'description' => __('Disable category link from meta in string', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'toggle',
							'name' => 'exclude_date_meta',
							'label' => __('Disable date', 'rehub_framework'),
							'description' => __('Disable date from meta in string', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'exclude_comments_meta',
							'label' => __('Disable comments count', 'rehub_framework'),
							'description' => __('Disable comments count from meta in string', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'toggle',
							'name' => 'post_view_disable',
							'label' => __('Disable post view script', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'disable_btn_offer_loop',
							'label' => __('Disable offer button in archives and loops?', 'rehub_framework'),
							'default' => '0',
						),																																																								
					),
				),
				array(
					'type' => 'section',
					'title' => __('Global disabling parts on single pages', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_fulltitle',
							'label' => __('Disable full width title?', 'rehub_framework'),
							'description' => __('This option disables big full width title and places it inside content', 'rehub_framework'),
							'default' => '0',
						),												
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_breadcrumbs',
							'label' => __('Disable breadcrumbs', 'rehub_framework'),
							'description' => __('Disable breadcrumbs from pages', 'rehub_framework'),
							'default' => '0',
						),

						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_share',
							'label' => __('Disable share buttons', 'rehub_framework'),
							'description' => __('Disable share buttons after content on pages', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_share_top',
							'label' => __('Disable share buttons', 'rehub_framework'),
							'description' => __('Disable share buttons before content on pages', 'rehub_framework'),
							'default' => '1',
						),											
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_prev',
							'label' => __('Disable previous and next', 'rehub_framework'),
							'description' => __('Disable previous and next post buttons', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_totop',
							'label' => __('Disable to top button', 'rehub_framework'),
							'default' => '0',
						),																	
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_tags',
							'label' => __('Disable tags', 'rehub_framework'),
							'description' => __('Disable tags after content from pages', 'rehub_framework'),
							'default' => '0',
						),
		
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_author',
							'label' => __('Disable author box', 'rehub_framework'),
							'description' => __('Disable author box after content from pages', 'rehub_framework'),
							'default' => '1',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_relative',
							'label' => __('Disable relative posts', 'rehub_framework'),
							'description' => __('Disable relative posts box after content from pages', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_enable_tag_relative',
							'label' => __('Enable relative posts by tags', 'rehub_framework'),
							'description' => __('By default, relative posts use category as base, you can switch to tags', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_feature_thumb',
							'label' => __('Disable top thumbnail on single page', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'toggle',
							'name' => 'rehub_disable_comments',
							'label' => __('Disable standart comments', 'rehub_framework'),
							'default' => '0',
						),							
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_widget_comments',
							'label' => __('Insert comments widget code', 'rehub_framework'),
							'description' => __('You can set here comments widget, for example, from disqus', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
						),																											

					),
				),
			),
		),
		array(
			'title' => __('Ads Options', 'rehub_framework'),
			'name' => 'menu_9',
			'icon' => 'font-awesome:fa-bullhorn',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Ads code in header and footer', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_ads_top',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This banner code will be visible in header. Width of this zone depends on style of header (You can choose it in Main Option tab)', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),	
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_ads_megatop',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This banner code will be visible before header.', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_ads_infooter',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This banner code will be visible before footer', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),																																				
					),
				),
				array(
					'type' => 'section',
					'title' => __('Global code for single page', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_single_after_title',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This code will be visible after title', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),	
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_single_before_post',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This code will be visible before post content', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),	
						 array(
							'type' => 'notebox',
							'name' => 'rehub_single_before_post_note',
							'label' => __('Tips', 'rehub_framework'),
							'description' => __('You can wrap your code with &lt;div class=&quot;right_code&quot;&gt;your ads code&lt;/div&gt; if you want to add right float or &lt;div class=&quot;left_code&quot;&gt;your ads code&lt;/div&gt; for left float. Please, use square ads with width 250-300px for floated ads.', 'rehub_framework'),
							'status' => 'info',
						),																	
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_single_code',
							'label' => __('Insert custom ads code', 'rehub_framework'),
							'description' => __('This code will be visible after post', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
							'default' => '',
						),	
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_shortcode_ads',
							'label' => __('Insert custom ads code for shortcode', 'rehub_framework'),
							'description' => __('You can insert this code in any place of content by shortcode [wpsm_ads1]', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
						),
						array(
							'type' => 'codeeditor',
							'name' => 'rehub_shortcode_ads_2',
							'label' => __('Insert custom ads code for shortcode', 'rehub_framework'),
							'description' => __('You can insert this code in any place of content by shortcode [wpsm_ads2]', 'rehub_framework'),
							'theme' => 'chrome',
							'mode' => 'html',
						),																							
					),
				),																
				array(
					'type' => 'section',
					'title' => __('Global branded area', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'notebox',
							'name' => 'rehub_branded_banner_note',
							'label' => __('Note', 'rehub_framework'),
							'description' => __('Branded area displays after header. You can set direct link on image or insert any html code or shortcode', 'rehub_framework'),
							'status' => 'normal',							
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_branded_banner_image',
							'label' => __('Branded area', 'rehub_framework'),
							'description' => __('Set any custom code or link to image', 'rehub_framework'),
							'default' => '',
						),												
					),
				),

			),
		),

		array(
			'title' => __('Reviews/Affiliate', 'rehub_framework'),
			'name' => 'menu_10',
			'icon' => 'font-awesome:fa-money',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Reviews, links, rating', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'type_user_review',
							'label' => __('Type of user ratings', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'simple',
									'label' => __('simple rating, no criterias', 'rehub_framework'),
								),
								array(
									'value' => 'full_review',
									'label' => __('full review with criterias and pros, cons', 'rehub_framework'),
								),	
								array(
									'value' => 'user',
									'label' => __('Show only user\'s reviews with criterias (don\'t show editor\'s review)', 'rehub_framework'),
								),									
								array(
									'value' => 'none',
									'label' => __('none', 'rehub_framework'),
								),																						
							),
							'default' => 'simple',
						),
						array(
							'type' => 'select',
							'name' => 'type_total_score',
							'label' => __('How to calculate total score of review', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'editor',
								'label' => __('based on editor\'s score', 'rehub_framework'),
								),
								array(
								'value' => 'average',
								'label' => __('average (editor\'s and user\'s)', 'rehub_framework'),
								),																
							),
							'dependency' => array(
								'field'    => 'type_user_review',
								'function' => 'rehub_framework_rev_type',
							),							
							'default' => 'average',
						),							
						array(
							'type' => 'textbox',
							'name' => 'rehub_user_rev_criterias',
							'label' => __('User review criteria names', 'rehub_framework'),
							'description' => __('Type with commas and no spaces. Example: Design,Price,Battery life', 'rehub_framework'),
							'dependency' => array(
								'field'    => 'type_user_review',
								'function' => 'user_rev_type',
							),							
						),
						array(
							'type' => 'select',
							'name' => 'type_schema_review',
							'label' => __('Type of schema for reviews', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'editor',
									'label' => __('Based on editor\'s review', 'rehub_framework'),
								),
								array(
									'value' => 'user',
									'label' => __('Based on user reviews', 'rehub_framework'),
								),																						
							),
							'default' => 'editor',
						),						
						array(
							'type' => 'toggle',
							'name' => 'Disable_product_schema',
							'label' => __('disable Product type schema for posts', 'rehub_framework'),
							'description' => __('check if you use your own schema plugins', 'rehub_framework'),							
							'default' => '0',							
						),																	
						array(
							'type' => 'toggle',
							'name' => 'enable_btn_userreview',
							'label' => __('Enable plus and minus buttons', 'rehub_framework'),
							'description' => __('This will work only in user reviews', 'rehub_framework'),							
							'default' => '0',							
						),																							
						array(
							'type' => 'select',
							'name' => 'allowtorate',
							'label' => __('Allow to rate posts', 'rehub_framework'),
							'description' => __('Who can rate review posts?', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'guests',
								'label' => __('guests', 'rehub_framework'),
								),
								array(
								'value' => 'users',
								'label' => __('users', 'rehub_framework'),
								),
								array(
								'value' => 'guests_users',
								'label' => __('guests and users', 'rehub_framework'),
								),								
								),
							'default' => 'guests_users',
						),
						array(
							'type' => 'select',
							'name' => 'color_type_review',
							'label' => __('Color type of review box', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'simple',
								'label' => __('one color', 'rehub_framework'),
								),
								array(
								'value' => 'multicolor',
								'label' => __('multicolor', 'rehub_framework'),
								),								
							),
							'default' => 'simple',
						),						
						array(
							'type' => 'color',
							'name' => 'rehub_review_color',
							'label' => __('Default color for editor\'s review box and total score', 'rehub_framework'),
							'description' => __('Choose the background color or leave blank for default red color', 'rehub_framework'),	
							'format' => 'hex',
							'dependency' => array(
								'field'    => 'color_type_review',
								'function' => 'rehub_framework_rev_color_is_mono',
							),							
						),	
						array(
							'type' => 'color',
							'name' => 'rehub_review_color_user',
							'label' => __('Default color for user review box and user stars', 'rehub_framework'),
							'description' => __('Choose the background color or leave blank for default blue color', 'rehub_framework'),	
							'format' => 'hex',
							'dependency' => array(
								'field'    => 'color_type_review',
								'function' => 'rehub_framework_rev_color_is_mono',
							),							
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_replace_color',
							'label' => __('Replace colors by category color', 'rehub_framework'),
							'description' => __('Do you want to replace default colors of review box with custom color of category?', 'rehub_framework'),							
							'default' => '0',
							'dependency' => array(
								'field'    => 'color_type_review',
								'function' => 'rehub_framework_rev_color_is_mono',
							),							
						),	
						array(
							'type' => 'color',
							'name' => 'rehub_userreview_multicolor',
							'label' => __('Color for stars in comments (default is blue)', 'rehub_framework'),
							'format' => 'hex',
							'dependency' => array(
								'field'    => 'color_type_review',
								'function' => 'rehub_framework_rev_color_is_multi',
							),							
						),
						array(
							'type' => 'multiselect',
							'name' => 'save_meta_for_ce',
							'label' => __('Save data from Content Egg to post offer section', 'rehub_framework'),
							'description' => __('This option will store data from Content Egg modules to main offer of post. Works only with enabled Content Egg plugin', 'rehub_framework'),	
							'items' => array(
								array(
									'value' => 'Amazon',
									'label' => 'Amazon',
								),	
								array(
									'value' => 'Ebay',
									'label' => 'Ebay',
								),	
								array(
									'value' => 'Zanox',
									'label' => 'Zanox',
								),
								array(
									'value' => 'Aliexpress',
									'label' => 'Aliexpress',
								),	
								array(
									'value' => 'CjProducts',
									'label' => 'CJ products',
								),
								array(
									'value' => 'AffilinetProducts',
									'label' => 'Affili.net',
								),
								array(
									'value' => 'Linkshare',
									'label' => 'Linkshare',
								),	
								array(
									'value' => 'Shareasale',
									'label' => 'Shareasale',
								),																																																																											
							),
							'default' => 'none',
						),	
						array(
							'type' => 'toggle',
							'name' => 'delete_meta_for_ce',
							'label' => __('Auto delete offer?', 'rehub_framework'),
							'description' => __('This option will automatically delete main post offer if Content Egg modules are empty. Be carefull if you have already offers in post offer section', 'rehub_framework'),							
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'enable_adsense_opt',
							'label' => __('Enable adsense optimized layout for desktop', 'rehub_framework'),
							'description' => __('Use this only if you have adsense as main money income source', 'rehub_framework'),							
							'default' => '0',							
						),																																														
					),
				),
			),
		),

		array(
			'title' => __('Localization', 'rehub_framework'),
			'name' => 'menu_loc',
			'icon' => 'font-awesome:fa-language',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Localization', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'textbox',
							'name' => 'rehub_currency',
							'label' => __('Set symbol of main currency (example, $)', 'rehub_framework'),
						),
						array(
							'type' => 'select',
							'name' => 'price_pattern',
							'label' => __('Choose price pattern', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'us',
								'label' => __('USA. Example: 1000.00', 'rehub_framework'),
								),
								array(
								'value' => 'eu',
								'label' => __('EU. Example: 1000,00', 'rehub_framework'),
								),	
								array(
								'value' => 'in',
								'label' => __('IN. Example: 1,000.00', 'rehub_framework'),
								),															
							),
							'default' => 'us',
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_btn_text',
							'label' => __('Set text for button', 'rehub_framework'),
							'description' => __('It will be used on button for product reviews, top rating pages instead BUY THIS ITEM', 'rehub_framework'),
							'validation' => 'maxlength[14]',
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_mask_text',
							'label' => __('Set text for coupon mask', 'rehub_framework'),
							'description' => __('It will be used on coupon mask instead REVEAL COUPON', 'rehub_framework'),
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_btn_text_aff_links',
							'label' => __('Set text for button', 'rehub_framework'),
							'description' => __('It will be used on button for products with list of links instead CHOOSE OFFER.', 'rehub_framework'),
							'validation' => 'maxlength[14]',
						),	
						array(
							'type' => 'textbox',
							'name' => 'rehub_btn_text_best',
							'label' => __('Set text for button', 'rehub_framework'),
							'description' => __('It will be used on button for products with comparison list instead BEST PRICE.', 'rehub_framework'),
						),						
						array(
							'type' => 'textbox',
							'name' => 'rehub_readmore_text',
							'label' => __('Set text for read more link', 'rehub_framework'),
							'description' => __('It will be used instead READ MORE', 'rehub_framework'),
						),
						array(
							'type' => 'textbox',
							'name' => 'rehub_choosedeal_text',
							'label' => __('Set text for deals list title', 'rehub_framework'),
							'description' => __('It will be used in list of offers instead CHOOSE YOUR DEAL', 'rehub_framework'),
						),																	
						array(
							'type' => 'textbox',
							'name' => 'rehub_review_text',
							'label' => __('Set text for full review link', 'rehub_framework'),
							'description' => __('It will be used in top review pages instead READ FULL REVIEW', 'rehub_framework'),
						),											
					),
				),
			),
		),

		array(
			'title' => __('User options', 'rehub_framework'),
			'name' => 'usersmenus',
			'icon' => 'font-awesome:fa-user',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Options for User login popup', 'rehub_framework'),
					'fields' => array(
						 array(
							'type' => 'notebox',
							'name' => 'rehub_user_note',
							'label' => __('Note!', 'rehub_framework'),
							'description' => __('Please, read about user functions in our <a href="http://rehub.wpsoul.com/documentation/docs.html#user1" target="_blank">documentation</a>.', 'rehub_framework'),
							'status' => 'info',
						),						
						array(
							'type' => 'toggle',
							'name' => 'userlogin_enable',
							'label' => __('Enable user login modal?', 'rehub_framework'),
							'description' => __('If you disable this, user modal will not work', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'select',
							'name' => 'rehub_login_icon',
							'label' => __('Add additional login icon in header', 'rehub_framework'),
							'description' => __('You can also add login-register link to any place with shortcode [wpsm_user_modal]', 'rehub_framework'),
							'items' => array(
								array(
									'value' => 'no',
									'label' => __('No additional icon', 'rehub_framework'),
								),
								array(
									'value' => 'top',
									'label' => __('In top line', 'rehub_framework'),
								),
								array(
									'value' => 'menu',
									'label' => __('In main menu', 'rehub_framework'),
								),															
							),
								'default' => array(
								'no',
							),
						),							
						array(
							'type' => 'toggle',
							'name' => 'userlogin_captcha_enable',
							'label' => __('Enable google captcha in modal?', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'textbox',
							'name' => 'userlogin_gapi_sitekey',
							'label' => __('Google API Site Key', 'rehub_framework'),
							'description' => __('A Google API Site Key for activating captcha. Register your <a href="https://www.google.com/recaptcha/admin#list">reCAPTCHA here</a>. Will not work on local virtual servers', 'rehub_framework'),
							'dependency' => array(
                            	'field' => 'userlogin_captcha_enable',
                            	'function' => 'vp_dep_boolean',
                            ),							
						),	
						array(
							'type' => 'textbox',
							'name' => 'userlogin_gapi_secretkey',
							'label' => __('Google API Secret Key', 'rehub_framework'),
							'description' => __('A Google API Secret Key for activating captcha. Register your <a href="https://www.google.com/recaptcha/admin#list">reCAPTCHA here</a>', 'rehub_framework'),
							'dependency' => array(
                            	'field' => 'userlogin_captcha_enable',
                            	'function' => 'vp_dep_boolean',
                            ),						
						),
						array(
							'type' => 'toggle',
							'name' => 'userlogin_terms_enable',
							'label' => __('Enable terms and conditions in modal?', 'rehub_framework'),
							'default' => '0',
						),						
						array(
							'type' => 'select',
							'name' => 'userlogin_term_page',
							'label' => __('Select page with Terms and Conditions', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_pages',
									),
								),
							),	
							'dependency' => array(
                            	'field' => 'userlogin_terms_enable',
                            	'function' => 'vp_dep_boolean',
                            ),												
						),
						array(
							'type' => 'select',
							'name' => 'userlogin_profile_page',
							'label' => __('Select page for user profile', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_pages',
									),
								),
							),													
						),	
						array(
							'type' => 'select',
							'name' => 'userlogin_submit_page',
							'label' => __('Select page for user submit', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_pages',
									),
								),
							),													
						),						
						array(
							'type' => 'toggle',
							'name' => 'remove_admin_bar',
							'label' => __('Disable admin bar for users?', 'rehub_framework'),
							'description' => __('Only admin can see admin bar', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'select',
							'name' => 'post_type_for_uu',
							'label' => __('Choose custom post type for UM', 'rehub_framework'),
							'description' => __('Choose custom post type which will show in profile (works with plugin Ultimate Member)', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value'  => 'rehub_get_cpost_type',
									),
								),
							),
							'default' => '',			
						),																																											
					),
				),
			),
		),

		array(
			'title' => __('Dynamic comparison', 'rehub_framework'),
			'name' => 'compare',
			'icon' => 'font-awesome:fa-database',
			'controls' => array(
				 array(
					'type' => 'notebox',
					'name' => 'rehub_user_note',
					'label' => __('Note!', 'rehub_framework'),
					'description' => __('Please, read about dynamic comparison in our <a href="http://rehub.wpsoul.com/documentation/docs.html#dynamicchart" target="_blank">documentation</a>.', 'rehub_framework'),
					'status' => 'info',
				),				
				array(
					'type' => 'section',
					'title' => __('Options for dynamic comparison functions', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'compare_page',
							'label' => __('Select page for comparison', 'rehub_framework'),
							'description' => __('Page must have top chart constructor template', 'rehub_framework'),
							'items' => array(
								'data' => array(
									array(
										'source' => 'function',
										'value' => 'vp_get_pages',
									),
								),
							),													
						),
						array(
							'type' => 'select',
							'name' => 'compare_btn_color',
							'label' => __('Choose color of button in compare panel', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'green',
								'label' => __('Green', 'rehub_framework'),
								),
								array(
								'value' => 'red',
								'label' => __('Red', 'rehub_framework'),
								),
								array(
								'value' => 'orange',
								'label' => __('Orange', 'rehub_framework'),
								),
								array(
								'value' => 'blue',
								'label' => __('Blue', 'rehub_framework'),
								),
								array(
								'value' => 'rosy',
								'label' => __('Rosy', 'rehub_framework'),
								),
								array(
								'value' => 'purple',
								'label' => __('Purple', 'rehub_framework'),
								),
								array(
								'value' => 'gold',
								'label' => __('Gold', 'rehub_framework'),
								),
								array(
								'value' => 'brown',
								'label' => __('Brown', 'rehub_framework'),
								),																																																								
							),
							'default' => 'green',
						),						
						array(
							'type' => 'toggle',
							'name' => 'compare_btn_single',
							'label' => __('Enable compare button in top of each single post?', 'rehub_framework'),
							'description' => __('You can also use [wpsm_compare_button] to insert button to any place', 'rehub_framework'),
							'default' => '0',
						),	
						array(
							'type' => 'textbox',
							'name' => 'compare_btn_cats',
							'label' => __('Set ids of categories where to show button', 'rehub_framework'),
							'dependency' => array(
                            	'field' => 'compare_btn_single',
                            	'function' => 'vp_dep_boolean',
                            ),
						),																					
					),
				),
			),
		),

		array(
			'title' => __('Shop settings', 'rehub_framework'),
			'name' => 'menu_woo',
			'icon' => 'font-awesome:fa-barcode',
			'controls' => array(
				array(
					'type' => 'section',
					'title' => __('Woocommerce settings', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'woo_columns',
							'label' => __('Set columns for woo archive', 'rehub_framework'),
							'items' => array(
								array(
								'value' => '3_col',
								'label' => __('3 columns', 'rehub_framework'),
								),
								array(
								'value' => '4_col',
								'label' => __('4 columns', 'rehub_framework'),
								),								
							),
							'default' => '3_col',
						),	
						array(
							'type' => 'select',
							'name' => 'woo_design',
							'label' => __('Set design of woo archive', 'rehub_framework'),
							'items' => array(
								array(
								'value' => 'simple',
								'label' => __('Simple columns', 'rehub_framework'),
								),
								array(
								'value' => 'grid',
								'label' => __('Grid', 'rehub_framework'),
								),								
							),
							'default' => 'simple',
						),
						array(
							'type' => 'select',
							'name' => 'woo_number',
							'label' => __('Set count of products in loop', 'rehub_framework'),
							'items' => array(
								array(
								'value' => '12',
								'label' => __('12', 'rehub_framework'),
								),
								array(
								'value' => '16',
								'label' => __('16', 'rehub_framework'),
								),								
							),
							'default' => '12',
						),	
						array(
							'type' => 'toggle',
							'name' => 'woo_btn_disable',
							'label' => __('Disable button in product loop?', 'rehub_framework'),
							'default' => '0',
						),
						array(
							'type' => 'toggle',
							'name' => 'woo_exclude_expired',
							'label' => __('Exclude products with expired coupons?', 'rehub_framework'),
							'description' => __('Useful when you use woocommerce for offers with coupons.', 'rehub_framework'),							
							'default' => '0',
						),							
						array(
							'type' => 'toggle',
							'name' => 'woo_slider_enable',
							'label' => __('Show image slider on product page?', 'rehub_framework'),
							'default' => '0',
						),																											
											
					),
				),
				array(
					'type' => 'section',
					'title' => __('Easydigitaldownload settings', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'select',
							'name' => 'rehub_framework_edd_layout',
							'label' => __('Select Easydigitaldownload Layout', 'rehub_framework'),
							'description' => __('Select what layout you want to use for archives of easydigitaldownload plugin pages.', 'rehub_framework'),
							'items' => array(							
								array(
									'value' => 'rehub_framework_edd_list',
									'label' => __('List Layout with left thumbnails', 'rehub_framework'),
								),
								array(
									'value' => 'rehub_framework_edd_grid',
									'label' => __('Grid layout with sidebar', 'rehub_framework'),
								),	
								array(
									'value' => 'rehub_framework_edd_gridfull',
									'label' => __('Full width Grid layout', 'rehub_framework'),
								),																									
							),
							'default' => array(
								'rehub_framework_edd_gridfull',
							),
						),
						array(
							'type' => 'toggle',
							'name' => 'rehub_framework_edd_rating',
							'label' => __('Enable rating?', 'rehub_framework'),
							'description' => __('Enable built-in user rating system?', 'rehub_framework'),
							'default' => '1',
						),	
						array(
							'type' => 'toggle',
							'name' => 'rehub_framework_edd_counter',
							'label' => __('Enable counter for sales and downloads?', 'rehub_framework'),
							'description' => __('Enable counter in widget download details?', 'rehub_framework'),
							'default' => '1',
						),										
					),
				),
				array(
					'type' => 'section',
					'title' => __('Ecwid settings', 'rehub_framework'),
					'fields' => array(
						array(
							'type' => 'toggle',
							'name' => 'rehub_ecwid_enable',
							'label' => __('Enable ecwid store customization?', 'rehub_framework'),
							'default' => '0',
						),										
					),
				),
			),
		),

		array(
			'title' => __('Custom badges for posts', 'rehub_framework'),
			'name' => 'badges',
			'icon' => 'font-awesome:fa-certificate',
			'controls' => array(				
				array(
					'type' => 'section',
					'title' => __('First badge', 'rehub_framework'),
					'fields' => array(
					    array(
					        'type' => 'html',
					        'name' => 'admin_badge_preview_1',
					        'binding' => array(
					            'field'    => 'badge_label_1, badge_color_1',
					            'function' => 'admin_badge_preview_html',
					        ),
					    ),						
						array(
							'type' => 'textbox',
							'name' => 'badge_label_1',
							'label' => __('Label', 'rehub_framework'),
							'default' => __('Editor choice', 'rehub_framework'),
							'validation' => 'maxlength[20]',	
						),						
						array(
							'type' => 'color',
							'name' => 'badge_color_1',
							'label' => __('Color', 'rehub_framework'),
							'format' => 'hex',	
						),						
					),
				),
				array(
					'type' => 'section',
					'title' => __('Second badge', 'rehub_framework'),
					'fields' => array(
					    array(
					        'type' => 'html',
					        'name' => 'admin_badge_preview_2',
					        'binding' => array(
					            'field'    => 'badge_label_2, badge_color_2',
					            'function' => 'admin_badge_preview_html',
					        ),
					    ),						
						array(
							'type' => 'textbox',
							'name' => 'badge_label_2',
							'label' => __('Label', 'rehub_framework'),
							'default' => __('Best seller', 'rehub_framework'),
							'validation' => 'maxlength[20]',																
						),						
						array(
							'type' => 'color',
							'name' => 'badge_color_2',
							'label' => __('Color', 'rehub_framework'),
							'format' => 'hex',	
						),						
					),
				),	
				array(
					'type' => 'section',
					'title' => __('Third badge', 'rehub_framework'),
					'fields' => array(
					    array(
					        'type' => 'html',
					        'name' => 'admin_badge_preview_3',
					        'binding' => array(
					            'field'    => 'badge_label_3, badge_color_3',
					            'function' => 'admin_badge_preview_html',
					        ),
					    ),						
						array(
							'type' => 'textbox',
							'name' => 'badge_label_3',
							'label' => __('Label', 'rehub_framework'),
							'default' => __('Best value', 'rehub_framework'),
							'validation' => 'maxlength[20]',															
						),						
						array(
							'type' => 'color',
							'name' => 'badge_color_3',
							'label' => __('Color', 'rehub_framework'),
							'format' => 'hex',	
						),						
					),
				),
				array(
					'type' => 'section',
					'title' => __('Fourth badge', 'rehub_framework'),
					'fields' => array(
					    array(
					        'type' => 'html',
					        'name' => 'admin_badge_preview_4',
					        'binding' => array(
					            'field'    => 'badge_label_4, badge_color_4',
					            'function' => 'admin_badge_preview_html',
					        ),
					    ),						
						array(
							'type' => 'textbox',
							'name' => 'badge_label_4',
							'label' => __('Label', 'rehub_framework'),
							'default' => __('Best price', 'rehub_framework'),
							'validation' => 'maxlength[20]',								
						),						
						array(
							'type' => 'color',
							'name' => 'badge_color_4',
							'label' => __('Color', 'rehub_framework'),
							'format' => 'hex',	
						),						
					),
				),											
			),
		),

	)
);

/**
 *EOF
 */