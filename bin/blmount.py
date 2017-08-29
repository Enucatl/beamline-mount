import click
import subprocess


@click.command()
@click.option("--uid", default="1001")
@click.option("--gid", default="1001")
@click.option("--username", help="e-account username")
@click.option("--password", help="e-account password")
@click.option("--server", help="network server X02DA")
@click.option("--mountdir", help="local mount destination")
def main(
        uid,
        gid,
        username,
        password,
        server,
        mountdir):
    command = "sudo mount -t cifs -o uid={uid},gid={gid},username={username},password={password},sec=ntlm //{server}/{username} {mountdir}".format(
            uid=uid,
            gid=gid,
            username=username,
            password=password,
            server=server,
            mountdir=mountdir
        )
    print(command)
    subprocess.check_call("sudo mkdir -p {0}".format(mountdir), shell=True)
    subprocess.check_call("sudo chown {0}:{1} {2}".format(
        uid, gid, mountdir), shell=True)
    subprocess.check_call(command, shell=True)

if __name__ == "__main__":
    main()
