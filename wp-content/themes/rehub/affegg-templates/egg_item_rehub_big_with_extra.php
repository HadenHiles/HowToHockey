<?php
/*
  Name: Big product cart with extra
 */
?>
<?php foreach ($items as $item): ?>
    <?php $offer_price = str_replace(' ', '', $item['price']); if($offer_price =='0') {$offer_price = '';} ?>
    <?php $offer_price_old = str_replace(' ', '', $item['old_price']); if($offer_price_old =='0') {$offer_price_old = '';} ?>
    <?php $afflink = $item['url'] ;?>
    <?php $aff_thumb = $item['img'] ;?>
    <?php $offer_title = wp_trim_words( $item['title'], 20, '...' ); ?>
    <?php $offer_desc = $item['description'] ;?>  
    <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>
    <?php if (!empty ($item['extra']['features'])) {$attributes = $item['extra']['features'];}  ?>
    <?php if (!empty ($item['extra']['images'])) {$gallery_images = $item['extra']['images'];}  ?>
    <?php if (!empty($item['extra']['comments'])) {$import_comments = $item['extra']['comments'];}  ?>   

    <div class="col_wrap_two">
        <div class="product_egg">

            <div class="image col_item">
                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                    <?php $params = array( 'width' => 500 );?>
                    <?php if (!empty($aff_thumb) ) :?> 
                        <img src="<?php echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php else :?>
                        <?php $image_id = get_post_thumbnail_id(get_the_ID());  $image_offer_url = wp_get_attachment_url($image_id);?>
                        <img src="<?php echo bfi_thumb( $image_offer_url, $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php endif ;?> 
                    <span class="show_more_images"><?php _e('Show more images', 'rehub_framework'); ?></span>
                    <?php if(!empty($offer_price_old) && $offer_price_old !='0') : ?>
                        <span class="sale_a_proc">
                            <?php   
                                $offer_price_calc = intval(str_replace(',', '', $item['price']));
                                $offer_price_old_calc = intval(str_replace(',', '', $item['old_price']));
                                $sale_proc = 0 -(100 - ($offer_price_calc / $offer_price_old_calc) * 100); 
                                $sale_proc = round($sale_proc); 
                                echo $sale_proc; echo '%';
                            ;?>
                        </span>
                    <?php endif ;?>                                   
                </a>
            </div>

            <div class="product-summary col_item">
            
	            <h2 class="product_title entry-title"><?php echo esc_attr($offer_title); ?> </h2>

	            <?php if(!empty($offer_price)) : ?>
	                <div class="deal-box-price" itemprop="offers" itemscope itemtype="http://schema.org/Offer">
	                    <sup class="cur_sign"><?php echo $item['currency']; ?></sup><?php echo $offer_price ?>
	                    <?php if(!empty($offer_price_old)) : ?>
	                    <span class="retail-old">
	                      <strike><span class="value"><?php echo $offer_price_old ?></span></strike>
	                    </span>
	                    <?php endif ;?>                
	                    <meta itemprop="price" content="<?php echo $item['price_raw'] ?>">
	                    <meta itemprop="priceCurrency" content="<?php echo $item['currency']; ?>">
	                    <?php if ($item['in_stock']): ?>
	                        <link itemprop="availability" href="http://schema.org/InStock">
	                    <?php endif ;?>                        
	                </div>                
	            <?php endif ;?>

	            <?php if ($offer_desc): ?>
	                <p><?php rehub_truncate('maxchar=200&text='.$offer_desc.''); ?></p>
	                <small class="small_size"><?php if ($item['in_stock']): ?><?php _e('Available: ', 'rehub_framework') ;?><span class="yes_available"><?php _e('In stock', 'rehub_framework') ;?></span><?php endif; ?></small>
	            <?php endif; ?>	            

	            <div class="buttons_col">
	                <div class="priced_block clearfix">
	                    <div>
	                        <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?> target="_blank" rel="nofollow">
	                            <?php echo $btn_txt ; ?>
	                            <span class="aff_tag mtinside"><?php echo rehub_get_site_favicon($item['orig_url']); ?></span>
	                        </a>
	                        <?php $offer_coupon_mask = 1 ?>
	                        <?php if(!empty($item['extra']['coupon']['code_date'])) : ?>
	                            <?php 
	                            $timestamp1 = strtotime($item['extra']['coupon']['code_date']); 
	                            $seconds = $timestamp1 - time(); 
	                            $days = floor($seconds / 86400);
	                            $seconds %= 86400;
	                            if ($days > 0) {
	                              $coupon_text = $days.' '.__('days left', 'rehub_framework');
	                              $coupon_style = '';
	                            }
	                            elseif ($days == 0){
	                              $coupon_text = __('Last day', 'rehub_framework');
	                              $coupon_style = '';
	                            }
	                            else {
	                              $coupon_text = __('Coupon is Expired', 'rehub_framework');
	                              $coupon_style = 'expired_coupon';
	                            }                 
	                            ?>
	                        <?php endif ;?>
	                        <?php  if(!empty($item['extra']['coupon']['code'])) : ?>
	                            <?php wp_enqueue_script('zeroclipboard'); ?>
	                            <?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
	                                <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($item['extra']['coupon']['code_date'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $item['extra']['coupon']['code'] ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $item['extra']['coupon']['code'] ?></span></div>   
	                            <?php else :?>
	                                <?php wp_enqueue_script('affegg_coupons'); ?>
	                                <div class="rehub_offer_coupon masked_coupon <?php if(!empty($item['extra']['coupon']['code_date'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $item['extra']['coupon']['code'] ?>" data-codetext="<?php echo $item['extra']['coupon']['code'] ?>" data-dest="<?php echo esc_url($item['url']) ?>"<?php echo $item['ga_event'] ?>><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>   
	                            <?php endif;?>
	                            <?php if(!empty($item['extra']['coupon']['code_date'])) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>    
	                        <?php endif ;?>                                                  
	                    </div>
	                </div>
	            </div> 

            </div>           

        </div> 
    </div>  

    <?php if (!empty ($attributes) || !empty ($gallery_images) || !empty ($import_comments)) :?>
	<div class="rehub_woo_review">
		
            <ul class="rehub_woo_tabs_menu">
                <?php if (!empty ($attributes)) :?><li class="affspec"><?php _e('Specification', 'rehub_framework') ?></li><?php endif ;?>
                <?php if (!empty ($gallery_images)) :?><li class="pretty_woo"><?php _e('Photos', 'rehub_framework') ?></li><?php endif ;?>
                <?php if (!empty ($import_comments)) :?><li class="affrev"><?php _e('Last reviews', 'rehub_framework') ?></li><?php endif ;?>                
            </ul>
        
        <div class="rehub_feat_block table_view_block">
            <?php if (!empty ($attributes)) :?>
                <div class="rehub_woo_review_tabs affspec">
                    <div>
                        <table class="shop_attributes">
                            <tbody>
                            <?php foreach ($attributes as $feature): ?>
                                <tr>
                                    <th><?php echo esc_html($feature['name']) ?></th>
                                    <td><p><?php echo esc_html($feature['value']) ?></p></td>
                                </tr>
                            <?php endforeach; ?>                                        
                            </tbody>
                        </table>
                    </div>                               
                </div>
            <?php endif ;?>
            <?php if (!empty ($gallery_images)) :?>
                <script>
                jQuery(document).ready(function($) {
                    'use strict'; 
                    $('.rehub_woo_review .pretty_woo a').attr('rel', 'prettyPhoto[rehub_product_gallery_<?php echo rand(1, 50);?>]');
                    $(".rehub_woo_review .pretty_woo a[rel^='prettyPhoto']").prettyPhoto({social_tools:false});
                });
                </script>
                <div class="rehub_woo_review_tabs pretty_woo">
                    <?php wp_enqueue_script('prettyphoto');
                        foreach ($gallery_images as $gallery_img) {
                            ?> 
                            <a href="<?php echo esc_attr($gallery_img) ;?>"> 
                            <img src="<?php $params = array( 'width' => 100, 'height' =>100 ); echo bfi_thumb( $gallery_img, $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />  
                            </a>
                            <?php
                        }
                    ?>
                </div>
            <?php endif ;?>
            <?php if (!empty ($import_comments)) :?>
                <div class="rehub_woo_review_tabs affrev">
			        <?php foreach ($import_comments as $key => $comment): ?>
			        	<div class="helpful-review black">
                            <div class="quote-top"><i class="fa fa-quote-left"></i></div>
                            <div class="quote-bottom"><i class="fa fa-quote-right"></i></div>
				            <div class="text-elips">
	                            <span><?php echo $comment['comment']; ?></span>
	                        </div>
	                        <?php if (!empty($comment['date'])): ?>
	                        	<span class="helpful-date"><?php echo gmdate("F j, Y", $comment['date']); ?></span>
	                        <?php endif ;?>
		                </div>
			        <?php endforeach; ?>
                </div>
            <?php endif ;?>                        
        </div>        
	</div>
	<?php endif ;?>
    <div class="clearfix"></div>
<?php endforeach; ?>         