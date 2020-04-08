<?php
/*
  Name: Specification from Icecat.biz (beta)
 */
use ContentEgg\application\helpers\TemplateHelper;  
?>
<?php include(locate_template('functions/icecat.php')); ?>
<?php foreach ($items as $item): ?>

    <?php $EAN = (!empty($item['extra']['itemAttributes']['EAN'])) ? $item['extra']['itemAttributes']['EAN'] : '' ;?>
    <?php $brand = (!empty($item['extra']['itemAttributes']['Brand'])) ? $item['extra']['itemAttributes']['Brand'] : '' ;?>
    <?php $sku = (!empty($item['extra']['itemAttributes']['MPN'])) ? $item['extra']['itemAttributes']['MPN'] : '' ;?>
    <?php
    $data = array(
        'language'  => substr(get_locale(), 0, 2),
        'username'  => 'openIcecat-xml',
        'password'  => 'freeaccess'
    );
    if ($EAN !='') {
       $data['ean'] = $EAN;
       $data = icecat_to_array($data);   
    }
    elseif ($brand !='' && $sku !='') {
        $data['brand'] = $brand;
        $data['sku'] = $sku;
        $data = icecat_to_array($data);
    }
    ?>
    <?php if(!isset($data['id'])) :?>
        <?php
            if(isset($data[1]))
            {
                echo '<div style="display:none">Error: '.$data[1].'</div>';
         
            } elseif(isset($data[2]))
            {
                echo '<div style="display:none">Error: '.$data[2].'</div>';
         
            } elseif(isset($data[3]))
            {
                echo '<div style="display:none">Error: '.$data[3].'</div>';
            }
        ?>
    <?php else :?>
        <div class="wpsm-toggle">
            <h3 class="wpsm-toggle-trigger"><?php _e('Specification:');?> <?php echo $item['title']?></h3>
            <div class="wpsm-toggle-container">
        <div class="wpsm-table wpsm-icecat-spec">
            <table>
                <?php foreach($data['spec'] as $id=>$s): ?>
                    <tr class="heading-th-spec">
                        <th title="Icecat specification category ID: <?php echo $id;?>" colspan="2"><?php echo $s['name'];?></th>
                    </tr>
                    <?php $i = 0; foreach($s['features'] as $id=>$f): ?>
                    <?php $i++; $odd = ($i % 2 == 1) ? ' class="odd"' : '';?>
                        <tr<?php echo $odd;?>>
                            <td title="Icecat specification feature ID: <?php echo $id;?>"><?php echo $f['name'];?></td>
                            <td><?php echo $f['pres_value'];?></td>
                        </tr>
                    <?php endforeach; ?>
                <?php endforeach; ?>
            </table> 
        </div>                
            </div>
        </div>      
    <?php endif ;?>    
 
<?php endforeach; ?>                   