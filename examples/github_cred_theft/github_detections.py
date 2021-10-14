import requests
import ipaddress

def get_actions_ranges()->list:
    return requests.get('https://api.github.com/meta').json()['actions']


def ipaddress_in_networks(target_address:str, networks:list)-> bool:

    for gh_address in networks:
        if ipaddress.ip_address(target_address) in ipaddress.ip_network(gh_address):
            return True
        else:
            return False
