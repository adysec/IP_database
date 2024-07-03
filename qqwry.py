import re
import json
import requests
from bs4 import BeautifulSoup

def get_link(url):
    headers = {
        'Accept-Language': 'zh-CN,zh;q=0.9,en-CN;q=0.8,en;q=0.7,zh-TW;q=0.6',
        'Cookie': 'rewardsn=; wxtokenkey=777',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
    }

    # 访问链接并从json中提取微信推文链接
    response = requests.get(url, headers=headers)
    data = json.loads(response.text)
    for i in data['getalbum_resp']['article_list']:
        if re.findall(r'纯真IP库社区版更新.*?', i["title"]):
            link = i['url']
            return link
    return None

def get_zip_url(link):
    # 访问微信推文链接并解析网页
    response = requests.get(link)
    soup = BeautifulSoup(response.text, 'html.parser')

    # 提取文本中的zip链接，正则匹配以https://开头以.zip后缀的链接
    content = soup.find('div', {'id': 'js_content'}).get_text()
    zip_url = re.findall(r'https://.*?\.zip', content)
    return zip_url

if __name__ == '__main__':
    # 从微信推文json数据中获得最新一期IP库的发布文章链接
    url = 'https://mp.weixin.qq.com/mp/appmsgalbum?__biz=Mzg3Mzc0NTA3NA==&action=getalbum&album_id=2329805780276838401&f=json'

    try:
        link = get_link(url)
        if link and link != "None" and link is not None:
            zip_url = get_zip_url(link)
            if zip_url and zip_url != "None" and zip_url is not None:
                print(zip_url[0])
            else:
                print("没有找到zip链接")
        else:
            print("没有找到微信推文链接")
    except Exception as e:
        print("出现错误：", e)
