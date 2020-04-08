<?php

namespace Keywordrush\AffiliateEgg;
/*
 Name: Etsy.com
 URI: http://www.etsy.com
 Icon: http://www.google.com/s2/favicons?domain=etsy.com
 CPA: 
 */
/**
 * EtsycomParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2014 keywordrush.com
 */
class EtsycomParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'USD';    
    
    public function parseCatalog($max)
    {
 	return array_slice($this->xpathArray(".//div[contains(@class,'buyer-card')]//a[contains(@class,'card-title')]/@href"), 0, $max);
    }

    public function parseTitle()
    {
        return $this->xpathScalar(".//h1/span[@itemprop='name']/text()");
        
    }

    public function parseDescription()
    {
        $res = $this->xpathArray(".//div[@id='tab-contents']//div[@id='description-text']");
        return sanitize_text_field(implode(' ', $res));
    }

    public function parsePrice() {
       $res = (float) preg_replace('/[^0-9\.]/', '', $this->xpathScalar(".//div[@id='listing-page-cart-inner']//meta[@itemprop='price']/@content"));
       return $res;
           
    }

    public function parseOldPrice() {
        return;
    }

    public function parseManufacturer()
    {
        return $this->xpathScalar(".//div[@id='seller']//span[@itemprop='title']");
    }

    public function parseImg()
    {
        $imageurl = $this->xpathScalar(".//meta[@property='og:image']/@content");
        return $imageurl;
    }

    public function parseImgLarge()
    {
        $imageurl = $this->xpathScalar(".//meta[@property='og:image']/@content");
        return $imageurl;       
    }

    public function parseExtra()
    {
        $extra = array();
        
        $extra['images'] = array();
        $results = $this->xpathArray(".//div[@id='image-main']/ul[@id='image-carousel']/li/@data-large-image-href");

        foreach ($results as $i => $res) {
            if ($i == 0)
                continue;
            if ($res) {
                $extra['images'][] = $res;
            }
        }
        return $extra;
    }

    public function isInStock()
    {
        $res = $this->xpath->evaluate("boolean(.//div[@id='item-stock']/meta[@itemprop='availability']/@content[contains(.,'in_stock')])");
        return ($res) ? true : false;          
    }

}