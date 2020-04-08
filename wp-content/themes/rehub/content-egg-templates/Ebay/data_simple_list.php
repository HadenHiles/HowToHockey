<?php
/*
  Name: Sorted simple list
 */

?>

<?php
use ContentEgg\application\helpers\TemplateHelper;
// sort items by price
usort($items, function($a, $b) {
    if (!$a['price']) return 1;
    if (!$b['price']) return -1;
    return $a['price'] - $b['price'];
});
$product_price_update = get_post_meta( get_the_ID(), '_cegg_last_update_Ebay', true );
$product_keyword_update = get_post_meta( get_the_ID(), '_cegg_last_bykeyword_update_Ebay', true );
if ($product_price_update) {
    $product_update = date("F j, Y, g:i a", $product_price_update);
}
elseif ($product_keyword_update) {
   $product_update = date("F j, Y, g:i a", $product_keyword_update);  
}
?>

<div class="egg_sort_list re_sort_list simple_sort_list mb20"><a name="aff-link-list"></a>
    <div class="aff_offer_links">
        <?php $i=0; foreach ($items as $key => $item): ?>
            <?php $afflink = $item['url'] ;?>
            <?php $aff_thumb = $item['img'] ;?>
            <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
            <?php $i++;?>  
            <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>  
            <div class="rehub_feat_block table_view_block<?php if ($i == 1){echo' best_price_item';}?>">
                
                    <div class="offer_thumb">   
                        <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>">
                            <?php if (!empty($aff_thumb) ) :?>  
                                <img src="<?php $params = array( 'width' => 100 ); echo bfi_thumb( esc_attr($aff_thumb), $params ); ?>" alt="<?php echo esc_attr($offer_title); ?>" />
                            <?php else :?>
                                <img src="<?php echo get_template_directory_uri(); ?>/images/default/noimage_100_70.png" alt="<?php echo esc_attr($offer_title); ?>" />
                            <?php endif ;?>                                    
                        </a>
                    </div>
                    <div class="desc_col desc_simple_col">
                        <div class="simple_title">
                            <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>">
                                <?php echo esc_attr($offer_title); ?>
                            </a>                            
                        </div>                                
                    </div>                    
                    <div class="desc_col price_simple_col">
                        <?php if(!empty($item['price'])) : ?>
                            <p itemprop="offers" itemscope itemtype="http://schema.org/Offer">
                                <span class="price_count">
                                    <span><?php echo $item['currency']; ?></span> <?php echo TemplateHelper::price_format_i18n($item['price']); ?>
                                    <?php if(!empty($item['priceOld'])) : ?>
                                    <strike>
                                        <span class="amount"><?php echo TemplateHelper::price_format_i18n($item['priceOld']); ?></span>
                                    </strike>
                                    <?php endif ;?>                                      
                                </span>
                                <?php if ($item['extra']['listingInfo']['bestOfferEnabled'] == true): ?>
                                    <span class="best_offer_badge"><?php _e('Best offer', 'rehub_framework') ?></span> 
                                <?php endif; ?>                                 
                                <meta itemprop="price" content="<?php echo $item['price'] ?>">
                                <meta itemprop="priceCurrency" content="<?php echo $item['currencyCode']; ?>">                        
                            </p>
                        <?php endif ;?>                        
                    </div>
                    <div class="desc_col shop_simple_col">
                        <div class="aff_tag mt10"><?php echo rehub_get_site_favicon('http://ebay.com'); ?></div>                         
                    </div>
                    <div class="buttons_col">
                        <div class="priced_block clearfix">
                            <div>
                                <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>" target="_blank" rel="nofollow">
                                    <?php echo $btn_txt ; ?>
                                </a>                                                        
                            </div>
                        </div>
                    </div>
                                                                          
            </div>
        <?php endforeach; ?>               
    </div>
    <?php if (!empty($product_update)) :?>
        <div class="last_update"><?php _e('Last update was on: ', 'rehub_framework'); ?><?php echo $product_update  ;?></div>
    <?php endif ;?>    
</div>
<div class="clearfix"></div>