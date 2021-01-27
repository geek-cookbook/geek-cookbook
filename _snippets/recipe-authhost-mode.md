### What is AuthHost mode

Under normal OIDC auth, you have to tell your auth provider which URLs it may redirect an authenticated user back to, post-authentication. This is a security feture of the OIDC spec, preventing a malicious landing page from capturing your session and using it to impersonate you. When you're securing many URLs though, explicitly listing them can be a PITA.

[@thomaseddon's traefik-forward-auth](https://github.com/thomseddon/traefik-forward-auth) includes an ingenious mechanism to simulate an "_auth host_" in your OIDC authentication, so that you can protect an unlimited amount of DNS names (_with a common domain suffix_), without having to manually maintain a list.

#### How does it work?

Say you're protecting **radarr.example.com**. When you first browse to **https://radarr.example.com**, Traefik forwards your session to traefik-forward-auth, to be authenticated. Traefik-forward-auth redirects you to your OIDC provider's login (_KeyCloak, in this case_), but instructs the OIDC provider to redirect a successfully authenticated session **back** to **https://auth.example.com/_oauth**, rather than to **https://radarr.example.com/_oauth**.

When you successfully authenticate against the OIDC provider, you are redirected to the "_redirect_uri_" of https://auth.example.com. Again, your request hits Traefik, which forwards the session to traefik-forward-auth, which **knows** that you've just been authenticated (_cookies have a role to play here_). Traefik-forward-auth also knows the URL of your **original** request (_thanks to the X-Forwarded-Whatever header_). Traefik-forward-auth redirects you to your original destination, and everybody is happy.

This clever workaround only works under 2 conditions:

1. Your "auth host" has the same domain name as the hosts you're protecting (_i.e., auth.example.com protecting radarr.example.com_)
2. You explictly tell traefik-forward-auth to use a cookie authenticating your **whole** domain (_i.e. example.com_)