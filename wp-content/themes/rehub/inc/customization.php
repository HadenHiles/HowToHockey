<?php ob_start(); ?>
<style type="text/css">
    <?php if (is_singular('post') && rehub_option('rehub_replace_color') =='1' && rehub_option('color_type_review') =='simple') :?>
    	<?php $category = get_the_category($post->ID); $first_cat = $category[0]->term_id; $cat_data = get_option("category_$first_cat");?>
			<?php if (!empty($cat_data['cat_color'])) :?>
				.category-<?php echo $first_cat ;?> .rate-line .filled, .category-<?php echo $first_cat ;?> .rate_bar_wrap .review-top .overall-score, .category-<?php echo $first_cat ;?> .rate-bar-bar{background-color: <?php echo $cat_data['cat_color'];?> !important; color:#fff !important; text-decoration: none;}
				.category-<?php echo $first_cat ;?> .rate_bar_wrap_two_reviews .score_val, .category-<?php echo $first_cat ;?> .rate_bar_wrap_two_reviews .user-review-criteria .score_val{border-color: <?php echo $cat_data['cat_color'];?>}
				.category-<?php echo $first_cat ;?>.user_reviews_view .userstar-rating span:before{color: <?php echo $cat_data['cat_color'];?>}
			<?php endif;?>
	<?php endif; ?>			 
	<?php if (rehub_option('rehub_bg_flat_color')) :?>
		body{background-color: <?php echo rehub_option('rehub_bg_flat_color') ?> ; background-image: none;}
	<?php endif; ?>	
	<?php if (rehub_option('rehub_review_color') && rehub_option('color_type_review') =='simple') :?>
		.rate-line .filled, .rate_bar_wrap .review-top .overall-score, .rate-bar-bar, .top_rating_item .score.square_score, .radial-progress .circle .mask .fill{background-color: <?php echo rehub_option('rehub_review_color') ?> ;}
		.meter-wrapper .meter, .rate_bar_wrap_two_reviews .score_val{border-color: <?php echo rehub_option('rehub_review_color') ?>;}
	<?php endif; ?>	
	<?php if (rehub_option('rehub_review_color_user') && rehub_option('color_type_review') =='simple') :?>
		.rate_bar_wrap_two_reviews .user-review-criteria .rate-bar-bar{background-color: <?php echo rehub_option('rehub_review_color_user') ?> ;}
		.userstar-rating span:before{color: <?php echo rehub_option('rehub_review_color_user') ?>;}
		.rate_bar_wrap_two_reviews .user-review-criteria .score_val{border-color: <?php echo rehub_option('rehub_review_color_user') ?>;}
	<?php endif; ?>
	<?php if (rehub_option('rehub_userreview_multicolor') && rehub_option('color_type_review') =='multicolor') :?>
		.userstar-rating span:before{color: <?php echo rehub_option('rehub_userreview_multicolor') ?>;}
	<?php endif; ?>		
	<?php if (rehub_option('rehub_color_link')) :?>
		article.post a{color: <?php echo rehub_option('rehub_color_link') ?>;}
	<?php endif; ?>				
	<?php if (vp_metabox('rehub_framework_brand.rehub_background_image_single') && (is_single() || is_page())) :?>
		<?php $bg_url = vp_metabox('rehub_framework_brand.rehub_background_image_single')?>
		<?php $bg_repeat = vp_metabox('rehub_framework_brand.rehub_background_repeat_single')?>
		<?php $bg_position = vp_metabox('rehub_framework_brand.rehub_background_position_single'); if ($bg_position =='') {$bg_position ='left';}?>
		<?php $bg_offset = vp_metabox('rehub_framework_brand.rehub_background_offset_single'); if ($bg_offset =='') {$bg_offset ='0';}?>
		<?php $bg_fixed = vp_metabox('rehub_framework_brand.rehub_background_fixed_single')?>
		<?php $bg_color = vp_metabox('rehub_framework_brand.rehub_color_background_single')?>
		<?php $bg_sized = vp_metabox('rehub_framework_brand.rehub_background_sized_single')?>
		body{background-color: <?php echo $bg_color ?> ; background-image: url("<?php echo $bg_url; ?>"); background-repeat: <?php echo $bg_repeat; ?>; background-position: <?php echo $bg_position ?> <?php echo $bg_offset ?>px; <?php if($bg_fixed) : ?>background-attachment:fixed;<?php endif; ?> <?php if($bg_sized) : ?>background-size:cover;<?php endif; ?>}
	<?php elseif (rehub_option('rehub_background_image') ) :?>
		<?php $bg_url = rehub_option('rehub_background_image');?>
		<?php $bg_repeat = rehub_option('rehub_background_repeat');?>
		<?php $bg_position = rehub_option('rehub_background_position');  if ($bg_position =='') {$bg_position ='left';}?>
		<?php $bg_offset = rehub_option('rehub_background_offset'); if ($bg_offset =='') {$bg_offset ='0';}?>
		<?php $bg_fixed = rehub_option('rehub_background_fixed')?>
		<?php $bg_color = rehub_option('rehub_color_background') ?>
		<?php $bg_sized = rehub_option('rehub_sized_background')?>
		body{background-color: <?php echo $bg_color ?> ;background-image: url("<?php echo $bg_url; ?>"); background-repeat: <?php echo $bg_repeat; ?>; background-position: <?php echo $bg_position ?> <?php echo $bg_offset ?>px; <?php if($bg_fixed) : ?>background-attachment:fixed;<?php endif; ?> <?php if($bg_sized) : ?>background-size:cover;<?php endif; ?>}
	<?php endif; ?>
	<?php if (vp_metabox('rehub_framework_brand.rehub_content_shadow_single') && (is_single() || is_page())) :?>
		.content, .block_style header{box-shadow: none;}
	<?php elseif (rehub_option('rehub_content_shadow') ) :?>
		.content, .block_style header{box-shadow: none;}
	<?php endif; ?>	
	<?php if (vp_metabox('rehub_framework_brand.rehub_branded_bg_url_single') && (is_single() || is_page())) :?>
		<?php $bg_branded_url = vp_metabox('rehub_framework_brand.rehub_branded_background_image_single')?>
		#branded_bg {height: 100%;left: 0;position: fixed;top: 0;width: 100%;z-index: 0;}
		footer, .top_theme, .content, .footer-bottom { position: relative; z-index: 1 }
  		/*header { position: relative; z-index: 99 }*/
	<?php elseif (rehub_option('rehub_branded_bg_url') ) :?>
		<?php $bg_branded_url = rehub_option('rehub_branded_background_image'); ?>
		#branded_bg {height: 100%;left: 0;position: fixed;top: 0;width: 100%;z-index: 0;}
		footer, .top_theme, .content, .footer-bottom { position: relative; z-index: 1 }
  		/*header { position: relative; z-index: 99 }*/
	<?php endif; ?>
	<?php if(rehub_option('rehub_branded_banner_image') || (vp_metabox('rehub_framework_brand.rehub_branded_banner_image_single') && (is_single() || is_page()))  ) : ?>
		.top_theme { display: none }
		header .main-nav { margin-bottom: 0 !important }
		.content.landing_page{ margin-top: 0 !important}
	<?php endif; ?>	
	<?php if (is_page_template('visual_builder.php')) :?>
		<?php if (vp_metabox('vcr.bg_disable') =='1') :?>body{ background: none #fff}<?php endif; ?>
	<?php endif; ?>
	<?php if (rehub_option('rehub_sticky_nav')) :?>
		header .main-nav{position: relative; z-index: 999;    width: 100%;}
		/*.top_theme{ padding-top: 10px}*/
	<?php endif; ?>
	<?php if(rehub_option('rehub_nav_font')) : ?>
		.dl-menuwrapper li a, nav.top_menu ul li a {
			font-family:"<?php echo rehub_option('rehub_nav_font'); ?>", trebuchet ms;
			font-weight:<?php echo rehub_option('rehub_nav_font_weight'); ?>!important;
			font-style:<?php echo rehub_option('rehub_nav_font_style');?>;
			<?php if(rehub_option('rehub_nav_font_trans') =='1') : ?>text-transform:none;<?php endif; ?>			
		}
	<?php endif; ?>	
	<?php if(rehub_option('rehub_headings_font')) : ?>
		h1, h2, h3, h4, h5, h6, #reviews_tabs > ul > li, .top_single_area h1, article h2, article h3, article h4, article h5, article h6, .cats_def a, #reviews_tabs .more, .tabs_img .video_overlay > div h3 a, .news_block .big_img .video_overlay h3, .btn_more, .widget.tabs > ul > li, .featured_slider .reviews, .sidebar .featured_slider .link, .sidebar .widget .title, .video_widget p, .footer-bottom .footer_widget .title_b, .footer-bottom .featured_slider .link, .title h1, .title h5, .small_post .overlay h2, .small_post blockquote p, .post_slider .caption a, .related_articles .related_title, #comments .title_comments, .commentlist .comment-author .fn, .commentlist .comment-author .fn a, .comment-respond h3, #commentform #submit, .media_video h4, .media_video > p, .best_from_cat_carousel h5 span, .shop_carousel .product_details h4, .shop_carousel .product_details .price, .shop_carousel .quick_buy, .wpsm-button.rehub_main_btn, .title_ecwid, .rate_bar_wrap .review-top .review-text span.review-header, .ap-pro-form-field-wrapper input[type="submit"] {
			font-family:"<?php echo rehub_option('rehub_headings_font'); ?>", trebuchet ms;
			font-weight:<?php echo rehub_option('rehub_headings_font_weight'); ?>;
			font-style:<?php echo rehub_option('rehub_headings_font_style'); ?>;
			<?php if(rehub_option('rehub_headings_font_trans') =='1') : ?>text-transform:none;<?php endif; ?>			
		}
	<?php endif; ?>
    <?php if(rehub_option('rehub_block_font')) : ?>
		.heading .head_section, .heading a, .heading h5{
			font-family:"<?php echo rehub_option('rehub_block_font'); ?>", trebuchet ms !important;
			font-weight:<?php echo rehub_option('rehub_block_font_weight'); ?>!important;
			font-style:<?php echo rehub_option('rehub_block_font_style'); ?>;
			<?php if(rehub_option('rehub_block_font_trans') =='1') : ?>text-transform:none;<?php endif; ?>			
		}
	<?php endif; ?>
	<?php if(rehub_option('rehub_slider_font')) : ?>
		.main_slider .flex-overlay h2, .main_slider .flex-overlay a.btn_more, .columns figure .sidecol-overlay h3 {
			font-family:"<?php echo rehub_option('rehub_slider_font'); ?>", trebuchet ms;
			font-weight:<?php echo rehub_option('rehub_slider_font_weight'); ?>!important;
			font-style:<?php echo rehub_option('rehub_slider_font_style'); ?>;
			<?php if(rehub_option('rehub_slider_font_trans') =='1') : ?>text-transform:none;<?php endif; ?>			
		}
	<?php endif; ?>
	<?php if(rehub_option('rehub_body_font')) : ?>
		.news .detail p, article, .small_post > p, .single .star .title_stars, .breadcrumb, footer div.f_text, .header-top .top-nav li, .related_articles ul li > a, .commentlist .comment-content p {
			font-family:"<?php echo rehub_option('rehub_body_font'); ?>", arial;
			font-weight:<?php echo rehub_option('rehub_body_font_weight'); ?>!important;
			font-style:<?php echo rehub_option('rehub_body_font_style'); ?>;			
		}
	<?php endif; ?>	
	<?php if(rehub_option('body_font_size')) : ?>
		article {
			font-size:<?php echo intval(rehub_option('body_font_size'));?>px;		
		}
	<?php endif; ?>		
    <?php if(rehub_option('rehub_custom_color_nav') !='') : ?>
		header .main-nav, .main-nav.dark_style, .header_menu_row .main-nav{
			background: none repeat scroll 0 0 <?php echo rehub_option('rehub_custom_color_nav'); ?>!important;
			box-shadow: none;			
		}
		.main-nav{ border-bottom: none;}
		.dl-menuwrapper .dl-menu{margin: 0 !important}
	<?php endif; ?>	
    <?php if(rehub_option('rehub_custom_color_top') !='') : ?>
		.header_top_wrap{
			background: none repeat scroll 0 0 <?php echo rehub_option('rehub_custom_color_top'); ?>!important;			
		}
		.header-top, .header_top_wrap{ border: none !important}
	<?php endif; ?>	
    <?php if(rehub_option('rehub_custom_color_top_font') !='') : ?>
		.header_top_wrap .user-ava-intop:after, .header-top .top-nav a, .header-top a.cart-contents, .header_top_wrap .icon-search-onclick:before, .header_top_wrap i.re-top-menu-collapse{
			color: <?php echo rehub_option('rehub_custom_color_top_font'); ?> !important;			
		}
		.header-top .top-nav li{border: none !important;}
	<?php endif; ?>			
    <?php if(rehub_option('rehub_custom_color_nav_font') !='') : ?>
		.main-nav .user-ava-intop:after, nav.top_menu ul li a, .dl-menuwrapper button i, .header_menu_row nav.top_menu > ul > li > a{
			color: <?php echo rehub_option('rehub_custom_color_nav_font'); ?> !important;			
		}
		nav.top_menu > ul > li > a:hover{box-shadow: none;}
	<?php endif; ?>	
	<?php if (rehub_option('rehub_header_color_background') !='') :?>
		#main_header{background-color: <?php echo rehub_option('rehub_header_color_background'); ?> !important }
		.header-top{border: none;}
	<?php endif; ?>
	<?php if (rehub_option('rehub_header_background_image') !='') :?>
		<?php $bg_header_url = rehub_option('rehub_header_background_image'); ?>
		<?php $bg_header_position = (rehub_option('rehub_header_background_position') !='') ? rehub_option('rehub_header_background_position') : 'left'; ?>
		<?php $bg_header_repeat = (rehub_option('rehub_header_background_repeat') !='') ? rehub_option('rehub_header_background_repeat') : 'repeat'; ?>
		#main_header {background-image: url("<?php echo $bg_header_url ?>") ; background-position: <?php echo $bg_header_position ?> top; background-repeat: <?php echo $bg_header_repeat ?>}
	<?php endif; ?>
    <?php if(rehub_option('rehub_homecarousel_color') =='1') : ?>
		#re_carousel .text { border-left: 1px solid #999; color: #111; box-shadow: 0 -1px 5px #aaa;
			background: #f4f4f4; /* Old browsers */
			background: -moz-linear-gradient(top,  #f4f4f4 0%, #ffffff 100%); /* FF3.6+ */
			background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#f4f4f4), color-stop(100%,#ffffff)); /* Chrome,Safari4+ */
			background: -webkit-linear-gradient(top,  #f4f4f4 0%,#ffffff 100%); /* Chrome10+,Safari5.1+ */
			background: -o-linear-gradient(top,  #f4f4f4 0%,#ffffff 100%); /* Opera 11.10+ */
			background: -ms-linear-gradient(top,  #f4f4f4 0%,#ffffff 100%); /* IE10+ */
			background: linear-gradient(to bottom,  #f4f4f4 0%,#ffffff 100%); /* W3C */
			filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#f4f4f4', endColorstr='#ffffff',GradientType=0 ); /* IE6-9 */
		}
		.re_carousel .preview .pattern{ border-left: 1px solid #444}
	<?php endif; ?>	
    <?php if(rehub_option('rehub_label_color') !='def') : ?>
		.home_carousel .stamp {background: url("<?php echo get_template_directory_uri(); ?>/images/label_<?php echo rehub_option('rehub_label_color'); ?>.png") no-repeat;}
	<?php endif; ?>		
    <?php if(rehub_option('rehub_sidebar_left') =='1') : ?>
		.main-side {float:right;}
		.sidebar{float: left}
		.woo_sidebar_deals_links .deals_woo_rehub{ float: left;}
	<?php endif; ?>
    <?php if(rehub_option('rehub_feature_color') !='') : ?>
		.main_slider .pattern {background-color: <?php echo rehub_option('rehub_feature_color'); ?>;}
	<?php endif; ?>
    <?php if(rehub_option('rehub_logo_margin') !='' && rehub_option('rehub_logo_margin') !='5') : ?>
		header .logo {padding-top: <?php echo rehub_option('rehub_logo_margin'); ?>px;}
	<?php endif; ?>							
<?php if(rehub_option('rehub_custom_color') || (rehub_option('rehub_color_schema') !='default' && rehub_option('rehub_color_schema') !='')) : ?>
	<?php 
		if (rehub_option('rehub_custom_color')) {
			$colorschema = rehub_option('rehub_custom_color');
		} 
		elseif (rehub_option('rehub_color_schema') =='blue') {
			$colorschema = '#258FEF';
		}
		elseif (rehub_option('rehub_color_schema') =='green') {
			$colorschema = '#75C000';
		}
		elseif (rehub_option('rehub_color_schema') =='violet') {
			$colorschema = '#6B3387';
		}
		elseif (rehub_option('rehub_color_schema') =='yellow') {
			$colorschema = '#F9BA00';
		}
	?>

a { color: <?php echo $colorschema; ?>; }
nav.top_menu > ul > li ul li a:hover { color: #111111 }
ul.postpagination li.active a, ul.postpagination li:hover a, ul.postpagination li a:focus  { color: #FFFFFF !important; }
.priced_block .btn_offer_block:hover {background: <?php echo $colorschema; ?>; text-decoration:none; opacity: 0.8}
.priced_block .btn_offer_block:hover:after {border-left-color: <?php echo $colorschema; ?>;}
.widget.tabs > ul > li:hover { color: #ffffff; }
.sidebar .dark_sidebar .tabs-item .detail .rcnt_meta a.cat{ color: #fff;}
.footer-bottom .widget .f_menu li a:hover { text-decoration: underline; }

.priced_block .btn_offer_block:active { background-color: <?php echo $colorschema; ?> !important; top: 2px;}
.wps-button.orange, .wps-button.rehub_main_btn { color: #fff; background-color: <?php echo $colorschema; ?> !important; background-image: none !important; border-radius: 3px !important; box-shadow: none !important; text-transform: uppercase; }
.wps-button.orange:hover, .wps-button.rehub_main_btn:hover { background: <?php echo $colorschema; ?> !important; background-position: left bottom !important }
.wps-button.orange:active, .wps-button.rehub_main_btn:active { background-color: <?php echo $colorschema; ?> !important; top: 2px; box-shadow: none !important }
.wps_promobox.rehub_promobox { border-left-color: <?php echo $colorschema; ?>!important; }
.top_rating_block .top_rating_item .rating_col a.read_full, .color_link{ color: <?php echo $colorschema; ?> !important;}
nav.top_menu > ul > li > a:hover, nav.top_menu > ul > li.current-menu-item a, .widget.top_offers .title:after{border-top-color: <?php echo $colorschema; ?>; }

nav.top_menu > ul > li ul, .main-nav.dark_style { border-bottom: 2px solid <?php echo $colorschema; ?>; }
.wpb_content_element.wpsm-tabs.n_b_tab .wpb_tour_tabs_wrapper .wpb_tabs_nav .ui-state-active a{ border-bottom: 3px solid <?php echo $colorschema; ?> !important }
.priced_block .btn_offer_block:after, .priced_block .btn_offer_block:active:after { border-left-color: <?php echo $colorschema; ?>;}
.featured_slider:hover .score, .top_chart_controls .controls:hover{border-color:<?php echo $colorschema; ?>;}
.btn_more:hover, .custom-checkbox label.checked:before, .custom-radio label.checked:before, .small_post .overlay .btn_more:hover, .def-carousel.sec_style_carousel .carousel-next:hover, .def-carousel.sec_style_carousel .carousel-prev:hover { border: 1px solid <?php echo $colorschema; ?>; color: #fff }
.author_quote, .wpsm-tabs ul.ui-tabs-nav .ui-state-active a { border-top: 3px solid <?php echo $colorschema; ?>; }
.wps_promobox { border-left: 3px solid <?php echo $colorschema; ?>; }
.gallery-pics .gp-overlay {  box-shadow: 0 0 0 4px <?php echo $colorschema; ?> inset; }
.post .rehub_woo_tabs_menu li.current{ border-top:2px solid <?php echo $colorschema; ?>;}

/*BGS*/
.openedprevnext .postNavigation a, .postNavigation a:hover, .widget.top_offers .title, #reviews_tabs .more, .top_chart_pagination a.selected, .woocommerce .widget_price_filter .ui-slider .ui-slider-handle, .woocommerce-page .widget_price_filter .ui-slider .ui-slider-handle, .main_slider .flex-control-paging li a.flex-active, .main_slider .flex-control-paging li a:hover, .widget_edd_cart_widget .edd-cart-number-of-items .edd-cart-quantity, .btn_more:hover, #reviews_tabs > ul > li.current, #reviews_tabs > ul > li:hover, .featured_slider:hover .score, .priced_block .btn_offer_block , #bbp_user_edit_submit, .bbp-topic-pagination a, .bbp-topic-pagination a, .title_deal_wrap, .woobtn_offer_block, input.mdf_button, .widget.tabs > ul > li:hover, .wps-members > strong:first-child , .custom-checkbox label.checked:after, .def-carousel.sec_style_carousel .carousel-next:hover, .def-carousel.sec_style_carousel .carousel-prev:hover, .post_slider .caption, .slider_post .caption, .post .btn:hover, .small_post .btn:hover, ul.postpagination li.active a, ul.postpagination li:hover a, ul.postpagination li a:focus, .quick_view_btn a:hover, .custom-radio label.checked:after, .post_slider .flex-control-nav li a.flex-active, .post_slider .flex-control-nav li a:hover, .top_theme h5 strong, .re_carousel .text:after, .widget.tabs .current, #topcontrol:hover, .featured_slider .flex-control-paging li a.flex-active, .featured_slider .flex-control-paging li a:hover { background: <?php echo $colorschema; ?>; }
@media (max-width: 768px) {
	.postNavigation a{ background: <?php echo $colorschema; ?>; }
}

/*color*/
blockquote p, .top_chart_controls .controls:hover, .flexslider .fa-pulse, .footer-bottom .widget .f_menu li a:hover, .comment_form h3 a, .bbp-body li.bbp-forum-info > a:hover, .bbp-body li.bbp-topic-title > a:hover, #subscription-toggle a:before, #favorite-toggle a:before, .sidebar .tabs-item .detail .rcnt_meta a, .aff_offer_links .aff_name a, .rehub_feat_block .start_price span, .news_lettr p a, .sidebar .featured_slider .link, .commentlist .comment-content small a, .related_articles .title_cat_related a, .heading a, article em.emph, .best_from_cat_carousel h5 a, .campare_table table.one td strong.red, .sidebar .tabs-item .detail p a, .category_tab h5 a:hover, .sidebar .widget p a, .footer-bottom .widget .title_b span, footer p a, .welcome-frase strong { color: <?php echo $colorschema; ?>; }

/*woo style btn*/
.woocommerce input.button.alt, .woocommerce .checkout-button.button, .woocommerce a.add_to_cart_button, .woocommerce-page a.add_to_cart_button, .woocommerce a.single_add_to_cart_button, .woocommerce-page a.single_add_to_cart_button, .woocommerce div.product form.cart .button, .woocommerce-page div.product form.cart .button, .woocommerce #content div.product form.cart .button, .woocommerce-page #content div.product form.cart .button{ background-color: <?php echo $colorschema; ?> !important; box-shadow: 0 2px 2px #E7E7E7 !important }
.woocommerce input.button.alt:hover, .woocommerce .checkout-button.button:hover, .woocommerce a.add_to_cart_button:hover, .woocommerce-page a.add_to_cart_button:hover, .woocommerce a.single_add_to_cart_button:hover, .woocommerce-page a.single_add_to_cart_button:hover, .woocommerce div.product form.cart .button:hover, .woocommerce-page div.product form.cart .button:hover, .woocommerce #content div.product form.cart .button:hover, .woocommerce-page #content div.product form.cart .button:hover{ background: <?php echo $colorschema; ?> !important;  }
.woocommerce .button.alt:active, .woocommerce .checkout-button.button:active, .woocommerce a.add_to_cart_button:active, .woocommerce-page a.add_to_cart_button:active, .woocommerce a.single_add_to_cart_button:active, .woocommerce-page a.single_add_to_cart_button:active, .woocommerce div.product form.cart .button:active, .woocommerce-page div.product form.cart .button:active, .woocommerce #content div.product form.cart .button:active, .woocommerce-page #content div.product form.cart .button:active { background-color: <?php echo $colorschema; ?> !important; }
	<?php if (rehub_option('rehub_ecwid_enable')) :?>
	/*ecwid*/
	html#ecwid_html body#ecwid_body div.ecwid-minicart-counter, html#ecwid_html body#ecwid_body .ecwid-AddressForm-buttonsPanel button.gwt-Button { background-color: <?php echo $colorschema; ?> !important; }
	html#ecwid_html body#ecwid_body div.ecwid-minicart-link * { color: <?php echo $colorschema; ?> !important; }
	html#ecwid_html body#ecwid_body td.ecwid-categories-vertical-table-cell.ecwid-categories-vertical-table-cell-selected span.ecwid-categories-category { background-color: <?php echo $colorschema; ?> !important; color: #fff !important; }
	html#ecwid_html body#ecwid_body div.ecwid-productBrowser-categoryPath a, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-categoryPath a:active, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-categoryPath a:visited { color: #111 !important; }
	html#ecwid_html body#ecwid_body .ecwid-productBrowser-subcategories-mainTable tbody tr td:hover > div { border: 1px solid <?php echo $colorschema; ?> !important }
	html#ecwid_html body#ecwid_body .ecwid-productBrowser-subcategories-mainTable tbody tr:nth-child(3n+2) td:hover > div{ border: 1px solid <?php echo $colorschema; ?> !important; border-top: none !important; background: <?php echo $colorschema; ?> none !important; color: #fff !important }
	html#ecwid_html body#ecwid_body div.ecwid-productBrowser-price { color: #A20505 !important; }
	html#ecwid_html body#ecwid_body div.ecwid-ProductBrowser-auth-anonim a, html#ecwid_html body#ecwid_body div.ecwid-ProductBrowser-auth-logged a, html#ecwid_html body#ecwid_body div.ecwid-pager span.ecwid-pager-link-disabled, html#ecwid_html body#ecwid_body div.ecwid-Invoice-cell-title { background-color: <?php echo $colorschema; ?> !important; }
	html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart div.ecwid-productBrowser-price { color: #A20505 !important; }
	html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-totalAmount { color: #A20505 !important; }
	html#ecwid_html body#ecwid_body div.ecwid-Checkout-blockTitle, html#ecwid_html body#ecwid_body table.ecwid-Checkout-blockTitle div.gwt-Label, html#ecwid_html body#ecwid_body table.ecwid-Checkout-blockTitle div.gwt-HTML { color: #444 !important; }
	html#ecwid_html body#ecwid_body div.ecwid-Checkout-BreadCrumbs-link-visited{color: <?php echo $colorschema; ?> !important; }
	html#ecwid_html body#ecwid_body div.ecwid-Checkout-BreadCrumbs-link-current {border-bottom: 3px solid <?php echo $colorschema; ?> !important; color: <?php echo $colorschema; ?> !important;}
	html#ecwid_html body#ecwid_body div.ecwid-Invoice-cell-title {background-color: <?php echo $colorschema; ?> !important; }
	html#ecwid_html body#ecwid_body div.ecwid-Invoice-productPrice{ color: #A20505 !important; }
	html#ecwid_html body#ecwid_body td.ecwid-Invoice-Header-OrderId span, html#ecwid_html body#ecwid_body td.ecwid-Invoice-Header-OrderId-long span, html#ecwid_html body#ecwid_body td.ecwid-Invoice-Header-OrderId-very-long span{ color: #A20505 !important; }
	html#ecwid_html body#ecwid_body div.ecwid-Invoice-Summary-value-price{ color: #A20505 !important; }
	html#ecwid_html body#ecwid_body .ecwid-ProductsList-content div.ecwid-productBrowser-productsGrid-productTopFragment-mouseover, html#ecwid_html body#ecwid_body .ecwid-ProductsList-content div.ecwid-productBrowser-productsGrid-productBottomFragment-mouseover { border: solid 1px #bbb !important; }
	html#ecwid_html body#ecwid_body .ecwid-ProductsList-content div.ecwid-productBrowser-productsGrid-productTopFragment-mouseover { border-bottom: none !important; box-shadow: none !important; }
	html#ecwid_html body#ecwid_body .ecwid-ProductsList-content div.ecwid-productBrowser-productsGrid-productBottomFragment-mouseover { border-top: solid 1px #DDD !important; }
	/*html#ecwid_html body#ecwid_body .ecwid a, html#ecwid_html body#ecwid_body .ecwid a:active, html#ecwid_html body#ecwid_body .ecwid a:visited{ color: #258FEF !important; }*/
	/* buttons */
	html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-up, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-ie6-up, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-ie6-up-hovering, html#ecwid_html body#ecwid_body button.ecwid-AccentedButton, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-down, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-ie6-down, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-ie6-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-up, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-ie6-up, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-down, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-ie6-down, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-ie6-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-up, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-ie6-up, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-down, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-ie6-down, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-ie6-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-up, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-ie6-up, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-down, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-down-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-ie6-down, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-ie6-down-hovering  { background-color: <?php echo $colorschema; ?> !important;  box-shadow: none !important; border-radius: 3px !important; -webkit-transition: all 0.4s ease 0s !important; -moz-transition: all 0.4s ease 0s !important; -ms-transition: all 0.4s ease 0s !important; -o-transition: all 0.4s ease 0s !important; transition: all 0.4s ease 0s !important; }
	html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-ContinueShoppingButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-AddToBagButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-productBrowser-cart-checkoutButton-ie6-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-up-hovering, html#ecwid_html body#ecwid_body div.ecwid-Checkout-placeOrderButton-ie6-up-hovering, html#ecwid_html body#ecwid_body button.ecwid-AccentedButton:hover { background-color: #111111 !important; background-position: left bottom !important }
	<?php endif; ?>

<?php endif; ?>
<?php if(rehub_option('rehub_btnoffer_color') !='') : ?>
	.wps-button.orange, .wps-button.rehub_main_btn { color: #fff; background-color: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; background-image: none !important; border-radius: 3px !important; box-shadow: none !important; text-transform: uppercase; }
	.priced_block .btn_offer_block:after, .priced_block .btn_offer_block:active:after { border-left-color: <?php echo rehub_option('rehub_btnoffer_color') ?>;}
	.priced_block .btn_offer_block:active { background-color: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; top: 2px;}
	.wps-button.orange:active, .wps-button.rehub_main_btn:active { background-color: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; top: 2px; box-shadow: none !important }
	.priced_block .btn_offer_block:hover {background: <?php echo rehub_option('rehub_btnoffer_color') ?>; text-decoration:none; opacity: 0.8}
	.priced_block .btn_offer_block:hover:after {border-left-color: <?php echo rehub_option('rehub_btnoffer_color') ?>;}	
	.wps-button.orange:hover, .wps-button.rehub_main_btn:hover { background: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; background-position: left bottom !important }
	.woocommerce input.button.alt, .woocommerce .checkout-button.button, .woocommerce a.add_to_cart_button, .woocommerce-page a.add_to_cart_button, .woocommerce a.single_add_to_cart_button, .woocommerce-page a.single_add_to_cart_button, .woocommerce div.product form.cart .button, .woocommerce-page div.product form.cart .button, .woocommerce #content div.product form.cart .button, .woocommerce-page #content div.product form.cart .button{ background-color: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; box-shadow: 0 2px 2px #E7E7E7 !important }
	.woocommerce input.button.alt:hover, .woocommerce .checkout-button.button:hover, .woocommerce a.add_to_cart_button:hover, .woocommerce-page a.add_to_cart_button:hover, .woocommerce a.single_add_to_cart_button:hover, .woocommerce-page a.single_add_to_cart_button:hover, .woocommerce div.product form.cart .button:hover, .woocommerce-page div.product form.cart .button:hover, .woocommerce #content div.product form.cart .button:hover, .woocommerce-page #content div.product form.cart .button:hover{ background: <?php echo rehub_option('rehub_btnoffer_color') ?> !important;  }
	.woocommerce .button.alt:active, .woocommerce .checkout-button.button:active, .woocommerce a.add_to_cart_button:active, .woocommerce-page a.add_to_cart_button:active, .woocommerce a.single_add_to_cart_button:active, .woocommerce-page a.single_add_to_cart_button:active, .woocommerce div.product form.cart .button:active, .woocommerce-page div.product form.cart .button:active, .woocommerce #content div.product form.cart .button:active, .woocommerce-page #content div.product form.cart .button:active { background-color: <?php echo rehub_option('rehub_btnoffer_color') ?> !important; }
	.priced_block .btn_offer_block, .woobtn_offer_block, input.mdf_button{ background: <?php echo rehub_option('rehub_btnoffer_color') ?>; }
<?php endif; ?>	
<?php if(rehub_option('enable_adsense_opt') !='') : ?>
	@media screen and (min-width: 1100px) {
	.header-top, header .logo-section, nav.top_menu, .top_theme, .footer-bottom .container, .footer-bottom.block_foot, footer#theme_footer.block_foot, footer#theme_footer .container, .block_style #main_header, .block_style header .logo-section, #branded_img, .header_menu_row { width: 1074px;}
	.content { width: 1044px; padding: 15px}
	.sidebar, .side-twocol{ width: 300px}
	.main-side, .gallery-pics, .main_slider.flexslider{width:728px;}
	.main_slider .flex-overlay h2{ font-size: 36px; line-height: 34px}
	.edd_downloads_list.edd_download_columns_1 .edd_download_inner > div.edd_download_text { text-align: left; width: 255px }
	.full_width .edd_downloads_list.edd_download_columns_1 .edd_download_inner > div.edd_download_text { width: 565px }
	.woo_sidebar_deals_links .deals_woo_rehub {width: 270px}
	.rehub_feat_block.table_view_block .desc_col{ padding: 0 7px}
	.offer_grid .offer_thumb{ height: 130px}
	.offer_grid .offer_thumb img, .offer_grid figure img{max-height: 130px}
	.vc_row.vc_rehub_container > .vc_col-sm-8 {width: 728px;}
	.vc_row.vc_rehub_container > .vc_col-sm-4 {width: 300px;}
	.block_style header .logo { margin-left: 20px; width: 235px }
	header .logo { width: 300px;}
	.top_rating_block.list_style_rating .desc_col{ width: 500px}
	.with_sidebar_rating.top_rating_block.list_style_rating .desc_col { width: 240px; }
	.with_sidebar_rating.top_rating_block.list_style_rating .buttons_col{ width: 150px}	
	}
<?php endif; ?>	
<?php if(rehub_option('badge_color_1') !='') : ?>
	.re-starburst.badge_1, .re-starburst.badge_1 span, .re-line-badge.badge_1, .re-ribbon-badge.badge_1 span{background: <?php echo rehub_option('badge_color_1')?>;}
	.table_view_charts .top_chart_item.badge_1{border-top: 1px solid <?php echo rehub_option('badge_color_1')?>;}
	.re-line-badge.re-line-table-badge.badge_1:before{border-top-color: <?php echo rehub_option('badge_color_1')?>}
	.re-line-badge.re-line-table-badge.badge_1:after{border-bottom-color: <?php echo rehub_option('badge_color_1')?>}
<?php endif;?>
<?php if(rehub_option('badge_color_2') !='') : ?>
	.re-starburst.badge_2, .re-starburst.badge_2 span, .re-line-badge.badge_2, .re-ribbon-badge.badge_2 span{background: <?php echo rehub_option('badge_color_2')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_2, .table_view_charts .top_chart_item.ed_choice_col.badge_2 li:first-child:before, .table_view_charts .top_chart_item.ed_choice_col.badge_2 > ul > li:last-child:before{border-top: 1px solid <?php echo rehub_option('badge_color_2')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_2 > ul > li:last-child{border-bottom:1px solid <?php echo rehub_option('badge_color_2')?>;}
	.re-line-badge.re-line-table-badge.badge_2:before{border-top-color: <?php echo rehub_option('badge_color_2')?>}
	.re-line-badge.re-line-table-badge.badge_2:after{border-bottom-color: <?php echo rehub_option('badge_color_2')?>}
<?php endif;?>
<?php if(rehub_option('badge_color_3') !='') : ?>
	.re-starburst.badge_3, .re-starburst.badge_3 span, .re-line-badge.badge_3, .re-ribbon-badge.badge_3 span{background: <?php echo rehub_option('badge_color_3')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_3, .table_view_charts .top_chart_item.ed_choice_col.badge_3 li:first-child:before, .table_view_charts .top_chart_item.ed_choice_col.badge_3 > ul > li:last-child:before{border-top: 1px solid <?php echo rehub_option('badge_color_3')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_3 > ul > li:last-child{border-bottom:1px solid <?php echo rehub_option('badge_color_3')?>;}
	.re-line-badge.re-line-table-badge.badge_3:before{border-top-color: <?php echo rehub_option('badge_color_3')?>}
	.re-line-badge.re-line-table-badge.badge_3:after{border-bottom-color: <?php echo rehub_option('badge_color_3')?>}
<?php endif;?>
<?php if(rehub_option('badge_color_4') !='') : ?>
	.re-starburst.badge_4, .re-starburst.badge_4 span, .re-line-badge.badge_4, .re-ribbon-badge.badge_4 span{background: <?php echo rehub_option('badge_color_4')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_4, .table_view_charts .top_chart_item.ed_choice_col.badge_4 li:first-child:before, .table_view_charts .top_chart_item.ed_choice_col.badge_4 > ul > li:last-child:before{border-top: 1px solid <?php echo rehub_option('badge_color_4')?>;}
	.table_view_charts .top_chart_item.ed_choice_col.badge_4 > ul > li:last-child{border-bottom:1px solid <?php echo rehub_option('badge_color_4')?>;}
	.re-line-badge.re-line-table-badge.badge_4:before{border-top-color: <?php echo rehub_option('badge_color_4')?>}
	.re-line-badge.re-line-table-badge.badge_4:after{border-bottom-color: <?php echo rehub_option('badge_color_4')?>}
<?php endif;?>
</style>
<?php 
	$dynamic_css = ob_get_contents();
	ob_end_clean();
	if (function_exists('rehub_quick_minify')) {
		echo rehub_quick_minify($dynamic_css);
	}
	else {echo $dynamic_css;}
?>