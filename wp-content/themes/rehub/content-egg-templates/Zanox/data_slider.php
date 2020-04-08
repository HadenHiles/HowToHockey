<?php
/*
  Name: Slider
 */
use ContentEgg\application\helpers\TemplateHelper;  
?>

<?php  wp_enqueue_script('flexslider'); ?>

<div class="post_slider media_slider blog_slider egg_cart_slider loading">
    <ul class="slides">        
        <?php foreach ($items as $item): ?>
        <?php $afflink = $item['url'] ;?>
        <?php $aff_thumb = $item['img'] ;?>
        <?php $offer_title = wp_trim_words( $item['title'], 20, '...' ); ?> 
        <?php $merchant = (!empty($item['merchant'])) ? $item['merchant'] : ''; ?> 
        <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>   
        <li>
            <div class="col_wrap_two">
                <div class="product_egg">

                    <div class="image col_item">
                        <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>">
                            <?php $params = array( 'width' => 500 );?>           
                            <?php if (!empty($aff_thumb) ) :?> 
                                <img src="<?php echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                            <?php else :?>
                                <?php $image_id = get_post_thumbnail_id(get_the_ID());  $image_offer_url = wp_get_attachment_url($image_id);?>
                                <img src="<?php echo bfi_thumb( $image_offer_url, $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                            <?php endif ;?> 
                            <?php if(!empty($item['percentageSaved'])) : ?>
                                <span class="sale_a_proc">
                                    <?php    
                                        echo '-'; echo $item['percentageSaved']; echo '%';
                                    ;?>
                                </span>
                            <?php endif ;?>                                   
                        </a>               
                    </div>

                    <div class="product-summary col_item">
                    
                        <h2 class="product_title entry-title"><?php echo esc_attr($offer_title); ?> </h2>  
                        <small class="small_size">
                            <?php if ($item['availability']): ?>
                                <?php _e('Available: ', 'rehub_framework') ;?><span class="yes_available"><?php _e('In stock', 'rehub_framework') ;?></span>
                                <br />
                            <?php endif; ?>                        
                        </small>                             

                        <?php if(!empty($item['price'])) : ?>
                            <div class="deal-box-price" itemprop="offers" itemscope itemtype="http://schema.org/Offer">
                                <sup class="cur_sign"><?php echo $item['currency']; ?></sup><?php echo TemplateHelper::price_format_i18n($item['price']); ?>
                                <?php if(!empty($item['priceOld'])) : ?>
                                <span class="retail-old">
                                  <strike><span class="value"><?php echo TemplateHelper::price_format_i18n($item['priceOld']); ?></span></strike>
                                </span>
                                <?php endif ;?>                
                                <meta itemprop="price" content="<?php echo $item['price'] ?>">
                                <meta itemprop="priceCurrency" content="<?php echo $item['currencyCode']; ?>">
                                <?php if ($item['availability']): ?>
                                    <link itemprop="availability" href="http://schema.org/InStock">
                                <?php endif ;?>                        
                            </div>                
                        <?php endif ;?>
                        <div class="buttons_col">
                            <div class="priced_block clearfix">
                                <div>
                                    <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>" target="_blank" rel="nofollow">
                                        <?php echo $btn_txt ; ?>
                                        <span class="aff_tag mtinside"><?php echo '@ '.$merchant; ?></span>
                                    </a>                                                
                                </div>
                            </div>
                        </div>                
                        <?php if ($item['description']): ?>
                            <p><?php echo $item['description']; ?></p>                     
                        <?php endif; ?>              
                    </div>           
                </div>
            </div>  
        </li>
        <?php endforeach; ?>                   
    </ul>
</div>