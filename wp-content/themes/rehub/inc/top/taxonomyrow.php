<?php 
$catalog_tax = $row['tax_name'];
if ($catalog_tax !='') :?>
    <div class="post-tax"> 
        <?php $terms = get_the_terms(get_the_ID(), $catalog_tax );
        if ($terms && ! is_wp_error($terms)) :
            $term_slugs_arr = array();
            foreach ($terms as $term) {
                $term_slugs_arr[] = ''.$term->name.'';
            }
            $terms_slug_str = join(", ", $term_slugs_arr);
            echo $terms_slug_str;
        endif;
        ?> 
    </div>
<?php endif ;?>