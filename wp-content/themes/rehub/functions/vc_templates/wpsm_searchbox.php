<?php
$by = $placeholder = $color = '';   
    $atts = vc_map_get_attributes( $this->getShortcode(), $atts );
    extract( $atts ); 
    if ($color =='') {$color = 'orange';}

?>
	
<div class="custom_search_box">
	<form  role="search" method="get" id="searchform" action="<?php echo home_url( '/' ); ?>">
	  <input type="text" name="s" placeholder="<?php echo $placeholder?>">
	  <input type="hidden" name="post_type" value="<?php echo $by?>" />
	  <i class="fa fa-search"></i>
	  <button type="submit" class="wpsm-button <?php echo $color?>"><i class="fa fa-arrow-right"></i></button>
	</form>
</div>
