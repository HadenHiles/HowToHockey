<div id="post-<?php the_ID(); ?>" class="clearfix multi_cat_artical">
	<div class="multi_cat_image">
		<?php if ( has_post_thumbnail() ) {
			$img = get_post_thumb();
			$params = array( 'width' => 60, 'height' => 60, 'crop' => true);
			echo '<img src="'.bfi_thumb( $img, $params ).'" alt="'.the_title_attribute(array("echo" => 0) ).'" width="60" height="60" />';
		}
		else {
			$nothumb = get_template_directory_uri() . '/images/noim.png';
			echo '<img src="'.$nothumb.'" alt="'.the_title_attribute(array("echo" => 0) ).'" width="60" height="60" />';
		}
		?>
	</div>
	<div class="multi_cat_info">		
		<div class="multi_cat_title"><a href="<?php the_permalink(); ?>" ><?php the_title(); ?></a></div>
	    <div class="rcnt_meta">
	  		<?php $category = get_the_category($post->ID); $first_cat = $category[0]->term_id;?>
	    	<?php meta_small( false, $first_cat, true, false );  ?>
	    </div>
	</div>
</div>
