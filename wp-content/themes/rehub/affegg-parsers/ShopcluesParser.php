<?php

namespace Keywordrush\AffiliateEgg;

/*
  Name: Shopclues.com
  URI: http://www.shopclues.com
  Icon: http://www.google.com/s2/favicons?domain=shopclues.com
  CPA:
 */

/**
 * ShopcluesParser class file
 *
 * @author keywordrush.com <support@keywordrush.com>
 * @link http://www.keywordrush.com/
 * @copyright Copyright &copy; 2015 keywordrush.com
 */
class ShopcluesParser extends ShopParser {

    protected $charset = 'utf-8';
    protected $currency = 'INR';

    public function parseCatalog($max)
    {
        $urls = array_slice($this->xpathArray(".//div[@class='details']/a[@class='name']/@href"), 0, $max);
        foreach ($urls as $key => $url)
        {
            if (!preg_match('/^http:/', $url))
                $urls[$key] = 'http://www.shopclues.com' . $url;
        }
        return $urls;
    }

    public function parseTitle()
    {
        return $this->xpathScalar(".//*[@id='content']//h1[@itemprop='name']");
    }

    public function parseDescription()
    {
        return trim($this->xpathScalar(".//*[@id='content_block_description']//div[@class='product-details-list']/p"));
    }

    public function parsePrice()
    {
        $price = preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[@class='product-pricing']//div[@class='price']/span"));
        if (!$price)
            $price = preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[@class='product-pricing']//div[@class='price']")); 
        return (float) $price;
    }

    public function parseOldPrice()
    {
        $price = preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[@class='product-pricing']//div/strike"));
        if (!$price)
            $price = preg_replace('/[^0-9]/', '', $this->xpathScalar(".//div[@class='product-pricing']//div/span"));            
        return (float) $price;
    }

    public function parseManufacturer()
    {
        return '';
    }

    public function parseImg()
    {
        $img = $this->xpathScalar(".//meta[@property='og:image']/@content");
        if (!$img)
            return '';
        
        $parts = explode('/', $img);
        return 'http://' . $parts[2] . '/' . $parts['3']. '/thumbnails/' . $parts['5']. '/320/320/' . str_replace('_', '', $parts['6']);
        return $img;
    }

    public function parseImgLarge()
    {
        return $this->xpathScalar(".//meta[@property='og:image']/@content");
    }

    public function parseExtra()
    {
        $extra = array();
        
        
        $extra['features'] = array();
        $feature_names = $this->xpathArray(".//*[@id='content_block_features']//div[@class='product-features-list']//label");
        $feature_values = $this->xpathArray(".//*[@id='content_block_features']//div[@class='product-features-list']//span");
        for ($i = 0; $i < count($feature_names); $i++)
        {
            if (empty($feature_values[$i]))
                continue;
            $feature = array();
            $feature['name'] = trim($feature_names[$i]);
            $feature['value'] = trim($feature_values[$i]);
            $extra['features'][] = $feature;
        }

        $extra['comments'] = array();
        $users = $this->xpathArray(".//*[@class='box_productreview']//div[@class='prd_review_username']");
        $dates = $this->xpathArray(".//*[@class='box_productreview']//*[@class='box_productreview_details_header_username_updatetime']");
        $comments = $this->xpathArray(".//*[@class='box_productreview']//*[@class='box_productreview_details_reviewtext']");
        for ($i = 0; $i < count($comments); $i++)
        {
            $comment['comment'] = sanitize_text_field(trim($comments[$i]));
            if (isset($dates[$i]))
                $comment['date'] = strtotime(trim($dates[$i]));
            if (isset($users[$i]))
                $comment['user'] = trim($users[$i]);

            $extra['comments'][] = $comment;
        }
        return $extra;
    }

    public function isInStock()
    {
        $in_stock = trim(strip_tags($this->xpathScalar(".//div[@class='product-options']//span[contains(@class,'in-stock')]")));
        if ($in_stock == 'In Stock')
            return true;
        else
            return false;        
    }

}
