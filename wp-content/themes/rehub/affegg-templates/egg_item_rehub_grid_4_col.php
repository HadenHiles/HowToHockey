<?php
/*
  Name: Grid of products (4 column)
 */
?>
<?php
// sort items by price
usort($items, function($a, $b) {
    if (!$a['price_raw']) return 1;
    if (!$b['price_raw']) return -1;
    return $a['price_raw'] - $b['price_raw'];
});
?>
<?php  wp_enqueue_script('masonry'); wp_enqueue_script('imagesloaded'); wp_enqueue_script('masonry_init'); ?>
<div class="masonry_grid_fullwidth fourth-col-gridhub egg_grid">
<?php $i=0; foreach ($items as $key => $item): ?>
    <?php $offer_price = str_replace(' ', '', $item['price']); if($offer_price =='0') {$offer_price = '';} ?>
    <?php $offer_price_old = str_replace(' ', '', $item['old_price']); if($offer_price_old =='0') {$offer_price_old = '';} ?>
    <?php $afflink = $item['url'] ;?>
    <?php $aff_thumb = $item['img'] ;?>
    <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
    <?php $i++;?>  
    <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>  
    <article class="small_post">
        <div>
            <figure>
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
                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                    <?php if (!empty($aff_thumb) ) :?>  
                        <img src="<?php $params = array( 'width' => 200 ); echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php else :?>
                        <img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_200_140.png" alt="<?php echo esc_attr($offer_title); ?>" />
                    <?php endif ;?>                                    
                </a>
            </figure>
            <div class="affegg_grid_title">
                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?>>
                    <?php echo esc_attr($offer_title); ?>
                </a>
            </div>
            <div class="buttons_col">
                <div class="priced_block clearfix">
                    <?php if(!empty($offer_price)) : ?>
                        <p itemprop="offers" itemscope itemtype="http://schema.org/Offer">
                            <span class="price_count">
                                <ins><span><?php echo $item['currency']; ?></span> <?php echo $offer_price ?></ins>
                                <?php if(!empty($offer_price_old)) : ?>
                                <del>
                                    <span class="amount"><?php echo $offer_price_old ?></span>
                                </del>
                                <?php endif ;?>                                      
                            </span> 
                            <meta itemprop="price" content="<?php echo $offer_price ?>">
                            <meta itemprop="priceCurrency" content="<?php echo $item['currency']; ?>">
                            <?php if ($item['in_stock']): ?>
                                <link itemprop="availability" href="http://schema.org/InStock">
                            <?php endif ;?>                         
                        </p>
                    <?php endif ;?>
                    <div>
                        <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>"<?php echo $item['ga_event'] ?> target="_blank" rel="nofollow">
                            <?php echo $btn_txt ; ?>
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
                        <div class="aff_tag mt10 small_size"><?php echo rehub_get_site_favicon($item['orig_url']); ?></div>                            
                    </div>
                </div>
            </div>            
        </div>
    </article>
<?php endforeach; ?>
</div>   
<div class="clearfix"></div>