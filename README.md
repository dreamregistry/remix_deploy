# REMIX DEPLOY

The development version of a DReAM package that deploys Remix app to ECS secured with Cognito.

## Usage

```shell
dream add remix_deploy
```

- Define the following functions in your app:

```ts
import { fetch, redirect } from '@remix-run/node'

// ...

export default async function authenticate(request: Request) {
    const auth = await fetch(process.env.AUTH_ENDPOINT!, {
        headers: {
            cookie: request.headers.get("Cookie") || "",
        }
    })
    if (auth.status !== 200) {
        throw redirect("/auth/login?state=" + encodeURIComponent(new URL(request.url).pathname))
    }
    return auth.json()
}
```

- In your loaders, use the `authenticate` function to authenticate requests:

```ts
export async function loader({request}: LoaderArgs) {
  const {
    accessToken,
    userInfo: {sub: userId, email, name}
  } = await authenticate(request)

  // ...

  return json({
    //...
  })
}
```

- Add the following Error Boundary to your root component to properly handle redirects to login page:

```tsx
export function ErrorBoundary() {
  const error = useRouteError();

  useEffect(() => {
    if(isRouteErrorResponse(error)) {
      if (error.status === 404 && error.data.includes("/auth/login")) {
        window.location.href = "/auth/login?state=" + encodeURIComponent(window.location.pathname)
      }
    }
  }, [error])

  return (
          <></>
  );
}
```

- Open your app through the reverse proxy url exported as `REVERSE_PROXY_ENDPOINT` environment variable.


## Available endpoints

This package deploys an authentication service that exposes some endpoints to
use inside your app:

- `/auth/login`: login through Cognito
- `/auth/logout`: logout through Cognito
- `AUTH_ENDPOINT` environment variable contains the full url for
  authenticating requests. You need to forward cookies to this endpoint with
  a `GET` request. Upon successful authentication, you will receive a `200`
  response status code with the following body:

```yaml
{
  "accessToken": "<access_token>",
  "userInfo": {
    "sub": "<user_id>",
    "email_verified": "<true | false>",
    "name": "<user's full name>",
    "email": "<user's email>",
    "username": "<user's username>"
  },
  "expiresAt": <unix_timestamp> # in seconds.
}
```

If the user is not authenticated, you will receive a `401` response status code.
This endpoint has to be called server-side.
