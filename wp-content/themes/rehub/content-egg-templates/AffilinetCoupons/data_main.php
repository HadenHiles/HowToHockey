<?php
/*
  Name: Main
 */

use ContentEgg\application\helpers\TemplateHelper;
?>

<div class="egg_sort_list cj_sort_list mb20"><a name="aff-link-list"></a>
    <div class="aff_offer_links">

            <?php $i=0; foreach ($items as $key => $item): ?>
                <?php $afflink = $item['url'] ;?>
                <?php $offer_title = wp_trim_words( $item['title'], 10, '...' ); ?>
                <?php $i++;?>  
                <?php if(rehub_option('rehub_btn_text') !='') :?><?php $btn_txt = rehub_option('rehub_btn_text') ; ?><?php else :?><?php $btn_txt = __('Check it', 'rehub_framework') ;?><?php endif ;?>  
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
                            <div class="egg-logo">
                                <img src="<?php echo esc_attr($item['img']);?>" alt="<?php echo esc_attr($offer_title); ?>" />
                            </div>                         
                        </div>
                        <div class="buttons_col">
                            <div class="priced_block clearfix">
                                <div>
                                    <a class="btn_offer_block" href="<?php echo esc_url($afflink) ?>" target="_blank" rel="nofollow">
                                        <?php echo $btn_txt ; ?>
                                    </a>
                                    <?php $offer_coupon_mask = '0' ?>
                                    <?php if(!empty($item['endDate'])) : ?>
                                        <?php 
                                        $timestamp1 = $item['endDate']; 
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
                                    <?php  if(!empty($item['code'])) : ?>
                                        <?php wp_enqueue_script('zeroclipboard'); ?>
                                        <?php if ($offer_coupon_mask !='1' && $offer_coupon_mask !='on') :?>
                                            <div class="rehub_offer_coupon not_masked_coupon <?php if(!empty($item['endDate'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo esc_html($item['code']); ?>"><i class="fa fa-scissors fa-rotate-180"></i><span class="coupon_text"><?php echo esc_html($item['code']); ?></span></div>   
                                        <?php else :?>
                                            <?php wp_enqueue_script('affegg_coupons'); ?>
                                            <div class="rehub_offer_coupon masked_coupon <?php if(!empty($item['endDate'])) {echo $coupon_style ;} ?>" data-clipboard-text="<?php echo esc_html($item['code']); ?>" data-codetext="<?php echo esc_html($item['code']); ?>" data-dest="<?php echo esc_url($item['url']) ?>"><?php if(rehub_option('rehub_mask_text') !='') :?><?php echo rehub_option('rehub_mask_text') ; ?><?php else :?><?php _e('Reveal coupon', 'rehub_framework') ?><?php endif ;?><i class="fa fa-external-link-square"></i></div>   
                                        <?php endif;?>
                                        <?php if(!empty($item['endDate'])) {echo '<div class="time_offer">'.$coupon_text.'</div>';} ?>    
                                    <?php endif ;?>                                                                                            
                                </div>
                            </div>
                        </div>
                    </div>                                                          
                </div>
            <?php endforeach; ?>
                   
    </div>
</div>
<div class="clearfix"></div>