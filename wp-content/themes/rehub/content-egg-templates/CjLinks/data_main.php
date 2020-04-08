<?php
/*
  Name: Main
 */

use ContentEgg\application\helpers\TemplateHelper;
?>

<div class="egg_sort_list cj_sort_list mb20"><a name="aff-link-list"></a>
    <div class="aff_offer_links">
        
        <?php if ($data = TemplateHelper::filterData($items, 'linkType', 'Text Link', true)): ?>

            <?php $i=0; foreach ($data as $key => $item): ?>
                <?php $afflink = $item['url'] ;?>
                <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
                <?php $i++;?>  
                <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Buy this item', 'rehub_framework') ;?><?php endif ;?>  
                <div class="rehub_feat_block table_view_block coupons_cegg_block">
                    <div class="rehub_woo_review_tabs" style="display:table-row">
                        <div class="desc_col">
                            <strong>
                                <a rel="nofollow" target="_blank" href="<?php echo esc_url($afflink) ?>">
                                    <?php echo esc_attr($offer_title); ?>
                                </a>                            
                            </strong> 
                            <?php if ($item['description']): ?>
                                <div class="r_offer_details">
                                    <?php $desc_len = strlen($item['description']);?>
                                    <?php if ($desc_len > 150) :?>                                                                            
                                        <span class="r_show_hide"><?php _e('Details +', 'rehub_framework') ?></span>
                                        <p class="open_dls_onclk"><?php echo $item['description']; ?></p>
                                    <?php else :?>
                                        <p><?php echo $item['description']; ?></p>
                                    <?php endif;?>
                                </div>                     
                            <?php endif; ?>                                                            
                        </div>                    
                        <div class="desc_col shop_simple_col">
                            <div class="aff_tag mt10">
                                <img title="<?php echo esc_attr($item['extra']['advertiserSite']); ?>" src="http://www.google.com/s2/favicons?domain=http://<?php echo esc_attr($item['extra']['advertiserSite']); ?>" alt="<?php echo esc_attr($item['extra']['advertiserName']);?>" /> 
                                <?php echo esc_html($item['extra']['advertiserSite']); ?>
                            </div>                         
                        </div>
                        <div class="buttons_col">
                            <div class="priced_block clearfix">
                                <div>
                                    <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>" target="_blank" rel="nofollow">
                                        <?php echo $btn_txt ; ?>
                                    </a>
                                    <?php $offer_coupon_mask = '0' ?>
                                    <?php if(!empty($item['extra']['promotionEndDate'])) : ?>
                                        <?php 
                                        $timestamp1 = $item['extra']['promotionEndDate']; 
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
                                    <?php  if(!empty($item['extra']['couponCode'])) : ?>
                                        <?php wp_enqueue_script('zeroclipboard'); ?>
                                        <?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
                                            <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($item['extra']['promotionEndDate'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $item['extra']['couponCode'] ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo $item['extra']['couponCode'] ?></span></div>   
                                        <?php else :?>
                                            <?php wp_enqueue_script('affegg_coupons'); ?>
                                            <div class="rehub_offer_coupon masked_coupon <?php if(!empty($item['extra']['promotionEndDate'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo $item['extra']['couponCode'] ?>" data-codetext="<?php echo $item['extra']['couponCode'] ?>" data-dest="<?php echo esc_url($item['url']) ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>   
                                        <?php endif;?>
                                        <?php if(!empty($item['extra']['promotionEndDate'])) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>    
                                    <?php endif ;?>                                                                                            
                                </div>
                            </div>
                        </div>
                    </div>                                                          
                </div>
            <?php endforeach; ?>

        <?php endif; ?>

        <?php if ($data = TemplateHelper::filterData($items, 'linkType', 'Banner', true)): ?>
            <div class="rehub_feat_block banner_cegg_block mb15">
                <?php foreach ($data as $item): ?>
                    <div class="floatleft mb15 mr15">
                        <a rel="nofollow" target="_blank" href="<?php echo $item['url']; ?>">                    
                            <img src="<?php echo esc_attr($item['img']); ?>" alt="<?php echo esc_attr($item['title']); ?>" class="img-responsive" />
                        </a>
                    </div>
                <?php endforeach; ?>       
            </div>        
        <?php endif; ?> 

        <?php if ($data = TemplateHelper::filterData($items, 'linkType', array('Text Link', 'Banner'), true, true)): ?>
            <div class="rehub_feat_block textlink_cegg_block mb15">
                <?php foreach ($data as $item): ?>
                    <div class="mb15">
                        <?php echo $item['extra']['linkHtml']; ?>
                    </div>                    
                <?php endforeach; ?>
            </div>
        <?php endif; ?>                    
    </div>
</div>
<div class="clearfix"></div>