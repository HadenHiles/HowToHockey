<?php
$title = $title_align = $el_width = $style = $color = $accent_color = $el_class = 
$uppercase = $font_size = $border_width = $add_icon = $i_type = $i_icon_fontawesome =
$i_icon_openiconic = $i_icon_typicons = $i_icon_entypo =
$i_icon_linecons = $i_color = $i_custom_color =
$i_background_style = $i_background_color =
$i_custom_background_color = $i_size = $i_css_animation = '';
$atts = vc_map_get_attributes( $this->getShortcode(), $atts );
extract( $atts );
$class = "vc_separator wpb_content_element wpsm_sep";

//$el_width = "90";
//$style = 'double';
//$title = '';
//$color = 'blue';

$class .= ($title_align!='') ? ' vc_'.$title_align : '';
$class .= ($uppercase!='') ? ' wpsm_uppercase' : '';
$class .= ($el_width!='') ? ' vc_el_width_'.$el_width : ' vc_el_width_100';
$class .= ($style!='') ? ' vc_sep_'.$style : '';
$class .= ( '' !== $border_width ) ? ' vc_sep_border_width_' . $border_width : '';
$class .= ( '' !== $align ) ? ' vc_sep_pos_' . $align : '';
if( $color!= '' && 'custom' != $color ) {
	$class .= ' vc_sep_color_' . $color;
}
$inline_css = ( 'custom' == $color && $accent_color!='') ? ' style="'.vc_get_css_color('border-color', $accent_color).'"' : '';
$font_size = ( $font_size!='') ? ' style="font-size:'.intval($font_size).'px"' : '';

$class .= $this->getExtraClass($el_class);
$css_class = apply_filters( VC_SHORTCODE_CUSTOM_CSS_FILTER_TAG, $class, $this->settings['base'], $atts );
$icon = '';
if ( 'true' === $add_icon ) {
	vc_icon_element_fonts_enqueue( $i_type );
	$icon = $this->getVcIcon( $atts );
}

?>
<div class="<?php echo esc_attr(trim($css_class)); ?>">
	<span class="vc_sep_holder vc_sep_holder_l"><span<?php echo $inline_css; ?> class="vc_sep_line"></span></span>
	<?php if($icon!=''): ?><?php echo $icon; ?><?php endif; ?>
	<?php if($title!=''): ?><h4<?php echo $font_size; ?>><?php echo $title; ?></h4><?php endif; ?>
	<span class="vc_sep_holder vc_sep_holder_r"><span<?php echo $inline_css; ?> class="vc_sep_line"></span></span>
</div>
<?php echo $this->endBlockComment('separator')."\n";