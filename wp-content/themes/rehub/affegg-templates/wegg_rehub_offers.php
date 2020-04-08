<?php
/*
  Name: Offers with button
 */
?>

<?php wp_enqueue_style('eggrehub'); ?>

<div class="woo_sidebar_deals_links">
    <div class="deals_woo_rehub">

        <?php $i=0; foreach ($items as $key => $item): ?>
            <?php $offer_price = str_replace(' ', '', $item['price']); if($offer_price =='0') {$offer_price = '';} ?>
            <?php $offer_price_old = str_replace(' ', '', $item['old_price']); if($offer_price_old =='0') {$offer_price_old = '';} ?>
            <?php $afflink = $item['url'] ;?>
            <?php $aff_thumb = $item['img'] ;?>
            <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
            <?php $i++;?>  
            <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('See deal', 'rehub_framework') ;?><?php endif ;?>     
            <div class="woorow_aff">
                <div class="product-pic-wrapper">
                    <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                        <?php if (!empty($aff_thumb) ) :?>  
                            <img src="<?php $params = array( 'width' => 100 ); echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                        <?php else :?>
                            <img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_100_70.png" alt="<?php echo esc_attr($offer_title); ?>" />
                        <?php endif ;?>                                    
                    </a>                
                </div>
                <div class="product-details">
                    <div class="product-name">
                        <div class="aff_name">
                            <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                                <?php echo esc_attr($offer_title); ?>
                            </a>
                        </div>
                    </div>
                    <div class="left_data_aff">
                        <?php if(!empty($offer_price)) : ?>
                            <div class="wooprice_count">
                                <span><?php echo $item['currency']; ?></span> <?php echo $offer_price ?>
                                <?php if(!empty($offer_price_old)) : ?>
                                <strike>
                                    <span class="amount"><?php echo $offer_price_old ?></span>
                                </strike>
                                <?php endif ;?>                                
                            </div>
                        <?php endif ;?>                  
                        <div class="wooaff_tag">
                            <?php echo rehub_get_site_favicon($item['orig_url']); ?>                             
                        </div>
                    </div>                 
                    <div class="woobuy_butt">
                        <a class="woobtn_offer_block" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?> target="_blank" rel="nofollow">
                            <?php echo esc_attr($btn_txt) ; ?>
                        </a>                    
                    </div>
                </div>
            </div>
        
        <?php endforeach; ?>
    </div>
</div>